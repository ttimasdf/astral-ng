import { handleUpdateRequest } from '../../server/update-api.js';

export default {
  fetch(request: Request): Promise<Response> {
    return handleUpdateRequest(request, 'latest');
  },
};
