export type ApiClientPlaceholder = {
  baseUrl: string
}

export function createApiClient(baseUrl: string): ApiClientPlaceholder {
  return {baseUrl}
}
