use std::io;
#[cfg(target_os = "windows")]
use std::process::Command;

#[cfg(target_os = "windows")]
use std::os::windows::process::CommandExt;

#[cfg(target_os = "windows")]
pub fn get_all_interfaces_metrics() -> io::Result<Vec<(String, u32)>> {
    // 设置UTF-8代码页并执行netsh命令
    let output = Command::new("cmd")
        .args(&[
            "/c",
            "chcp 65001 >nul && netsh interface ipv4 show interfaces",
        ])
        .creation_flags(0x08000000) // CREATE_NO_WINDOW
        .output()?;

    if !output.status.success() {
        let error_msg = String::from_utf8(output.stderr)
            .unwrap_or_else(|e| String::from_utf8_lossy(&e.into_bytes()).to_string());
        return Err(io::Error::new(io::ErrorKind::Other, error_msg));
    }

    // 尝试使用UTF-8解码，失败则使用lossy转换
    let output_str = String::from_utf8(output.stdout)
        .unwrap_or_else(|e| String::from_utf8_lossy(&e.into_bytes()).to_string());

    let mut interfaces = Vec::new();

    for line in output_str.lines().skip(3) {
        // 跳过前三行表头
        if line.trim().is_empty() {
            continue;
        }

        let parts: Vec<&str> = line.split_whitespace().collect();
        if parts.len() >= 5 {
            let name = parts[4..].join(" ");
            let metric = parts[1].parse::<u32>().unwrap_or(0);
            interfaces.push((name, metric));
        }
    }

    Ok(interfaces)
}
#[cfg(not(target_os = "windows"))]
pub fn get_all_interfaces_metrics() -> io::Result<Vec<(String, u32)>> {
    Ok(Vec::new())
}

#[cfg(target_os = "windows")]
pub fn set_interface_metric(interface_name: &str, metric: u32) -> io::Result<()> {
    // 设置 IPv4 跃点
    let cmd_ipv4 = format!(
        "chcp 65001 >nul && netsh interface ipv4 set interface \"{}\" metric={}",
        interface_name, metric
    );
    let output_ipv4 = Command::new("cmd")
        .args(&["/c", &cmd_ipv4])
        .creation_flags(0x08000000) // CREATE_NO_WINDOW
        .output()?;

    if !output_ipv4.status.success() {
        let error_msg = String::from_utf8(output_ipv4.stderr.clone())
            .unwrap_or_else(|_| String::from_utf8_lossy(&output_ipv4.stderr).to_string());
        return Err(io::Error::new(
            io::ErrorKind::Other,
            format!("Failed to set IPv4 metric: {}", error_msg),
        ));
    }

    // 设置 IPv6 跃点
    let cmd_ipv6 = format!(
        "chcp 65001 >nul && netsh interface ipv6 set interface \"{}\" metric={}",
        interface_name, metric
    );
    let output_ipv6 = Command::new("cmd")
        .args(&["/c", &cmd_ipv6])
        .creation_flags(0x08000000) // CREATE_NO_WINDOW
        .output()?;

    if !output_ipv6.status.success() {
        let error_msg = String::from_utf8(output_ipv6.stderr.clone())
            .unwrap_or_else(|_| String::from_utf8_lossy(&output_ipv6.stderr).to_string());
        return Err(io::Error::new(
            io::ErrorKind::Other,
            format!("Failed to set IPv6 metric: {}", error_msg),
        ));
    }

    Ok(())
}

#[cfg(not(target_os = "windows"))]
pub fn set_interface_metric(_interface_name: &str, _metric: u32) -> io::Result<()> {
    Ok(())
}
