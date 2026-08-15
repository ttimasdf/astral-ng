import { handleUpdateRequest } from '../../src/update-api.js';

export default {
  fetch(request: Request): Promise<Response> {
    return handleUpdateRequest(request, 'latest');
  },
};
