import { serve } from 'bun';

import { handleUpdateRequest } from './update-api.js';

const port = Number(process.env.PORT ?? 3100);

serve({
  port,
  async fetch(request) {
    const path = new URL(request.url).pathname;
    if (path === '/api/v1/update') {
      return handleUpdateRequest(request, 'latest');
    }
    if (path === '/api/v1/versions') {
      return handleUpdateRequest(request, 'versions');
    }
    return new Response('Not Found', { status: 404 });
  },
});

console.log(`Update API listening at http://127.0.0.1:${port}`);
