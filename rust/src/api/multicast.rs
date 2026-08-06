use flutter_rust_bridge::frb;
use lazy_static::lazy_static;
use std::net::SocketAddr;
use tokio::io;
use tokio::net::UdpSocket;
use tokio::runtime::Runtime;
use tokio::sync::Mutex;
use tokio::task::JoinHandle;
use tokio::time::{interval, Duration};
use tokio_util::sync::CancellationToken;

lazy_static! {
    static ref RT: Runtime = Runtime::new().expect("创建 Tokio 运行时失败");
    static ref MULTICAST_SENDERS: Mutex<Vec<MulticastSender>> = Mutex::new(Vec::new());
}

#[frb(opaque)]
pub struct MulticastSender {
    multicast_addr: SocketAddr,
    bind_addr: String,
    data: Vec<u8>,
    interval_ms: u64,
    handle: Option<JoinHandle<()>>,
    cancel_token: Option<CancellationToken>,
}

impl MulticastSender {
    #[frb(ignore)]
    pub fn new(
        multicast_addr: impl Into<String>,
        port: u16,
        data: Vec<u8>,
        interval_ms: u64,
    ) -> io::Result<Self> {
        let multicast_addr: String = multicast_addr.into();
        let multicast_addr = format!("{}:{}", multicast_addr, port)
            .parse::<SocketAddr>()
            .map_err(|e| io::Error::new(io::ErrorKind::InvalidInput, e))?;

        Ok(Self {
            multicast_addr,
            bind_addr: "0.0.0.0:0".to_string(),
            data,
            interval_ms,
            handle: None,
            cancel_token: None,
        })
    }

    #[frb(ignore)]
    pub fn with_bind_addr(mut self, bind_addr: impl Into<String>) -> Self {
        self.bind_addr = bind_addr.into();
        self
    }

    pub async fn start(&mut self) -> io::Result<()> {
        if self.handle.is_some() {
            return Err(io::Error::new(io::ErrorKind::AlreadyExists, "组播已启动"));
        }

        let socket = UdpSocket::bind(&self.bind_addr).await?;
        let multicast_addr = self.multicast_addr;
        let data = self.data.clone();
        let interval_ms = self.interval_ms;
        let cancel_token = CancellationToken::new();
        let cancel_token_clone = cancel_token.clone();

        let handle = tokio::spawn(async move {
            let mut ticker = interval(Duration::from_millis(interval_ms));
            loop {
                tokio::select! {
                    _ = cancel_token_clone.cancelled() => {
                        break;
                    }
                    _ = ticker.tick() => {
                        let _ = socket.send_to(&data, multicast_addr).await;
                    }
                }
            }
        });

        self.handle = Some(handle);
        self.cancel_token = Some(cancel_token);
        Ok(())
    }

    pub async fn stop(&mut self) {
        if let Some(cancel_token) = self.cancel_token.take() {
            cancel_token.cancel();
        }
        if let Some(handle) = self.handle.take() {
            let _ = handle.await;
        }
    }

    pub fn is_running(&self) -> bool {
        self.handle.is_some()
    }
}

// Flutter 友好的 API

/// 创建并启动一个组播发送器
/// 返回发送器索引，用于后续操作
pub fn create_multicast_sender(
    multicast_addr: String,
    port: u16,
    data: Vec<u8>,
    interval_ms: u64,
) -> Result<usize, String> {
    RT.block_on(async move {
        let mut sender = match MulticastSender::new(multicast_addr.clone(), port, data, interval_ms)
        {
            Ok(s) => s,
            Err(e) => return Err(format!("创建组播发送器失败: {}", e)),
        };

        match sender.start().await {
            Ok(_) => {
                let mut senders = MULTICAST_SENDERS.lock().await;
                senders.push(sender);
                let index = senders.len() - 1;
                tracing::info!(
                    target: "astral.connection",
                    event_code = "multicast.sender.start",
                    sender_index = index,
                    interval_ms,
                    custom_bind = false,
                    "Multicast sender started"
                );
                Ok(index)
            }
            Err(e) => Err(format!("启动组播发送器失败: {}", e)),
        }
    })
}

/// 创建并启动一个组播发送器（带自定义绑定地址）
pub fn create_multicast_sender_with_bind(
    multicast_addr: String,
    port: u16,
    bind_addr: String,
    data: Vec<u8>,
    interval_ms: u64,
) -> Result<usize, String> {
    RT.block_on(async move {
        let mut sender = match MulticastSender::new(multicast_addr.clone(), port, data, interval_ms)
        {
            Ok(s) => s.with_bind_addr(bind_addr.clone()),
            Err(e) => return Err(format!("创建组播发送器失败: {}", e)),
        };

        match sender.start().await {
            Ok(_) => {
                let mut senders = MULTICAST_SENDERS.lock().await;
                senders.push(sender);
                let index = senders.len() - 1;
                tracing::info!(
                    target: "astral.connection",
                    event_code = "multicast.sender.start",
                    sender_index = index,
                    interval_ms,
                    custom_bind = true,
                    "Multicast sender started"
                );
                Ok(index)
            }
            Err(e) => Err(format!("启动组播发送器失败: {}", e)),
        }
    })
}

/// 停止指定索引的组播发送器
pub fn stop_multicast_sender(index: usize) -> Result<(), String> {
    RT.block_on(async move {
        let mut senders = MULTICAST_SENDERS.lock().await;

        if index >= senders.len() {
            return Err(format!("无效的发送器索引: {}", index));
        }

        senders[index].stop().await;
        tracing::info!(
            target: "astral.connection",
            event_code = "multicast.sender.stop",
            sender_index = index,
            "Multicast sender stopped"
        );
        Ok(())
    })
}

/// 停止所有组播发送器
pub fn stop_all_multicast_senders() -> Result<(), String> {
    RT.block_on(async move {
        let mut senders = MULTICAST_SENDERS.lock().await;

        let sender_count = senders.len();
        for sender in senders.iter_mut() {
            sender.stop().await;
        }

        senders.clear();
        tracing::info!(
            target: "astral.connection",
            event_code = "multicast.senders.stop",
            sender_count,
            "All multicast senders stopped"
        );
        Ok(())
    })
}

/// 获取所有正在运行的组播发送器数量
pub fn get_multicast_sender_count() -> usize {
    RT.block_on(async move {
        let senders = MULTICAST_SENDERS.lock().await;
        senders.len()
    })
}

/// 检查指定发送器是否正在运行
pub fn is_multicast_sender_running(index: usize) -> bool {
    RT.block_on(async move {
        let senders = MULTICAST_SENDERS.lock().await;

        if index >= senders.len() {
            return false;
        }

        senders[index].is_running()
    })
}
