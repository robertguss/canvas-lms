import test from 'node:test'
import assert from 'node:assert/strict'
import {readFile} from 'node:fs/promises'

test('package metadata declares the React Vite TypeScript scaffold', async () => {
  const packageJsonPath = new URL('../package.json', import.meta.url)
  const packageJson = JSON.parse(await readFile(packageJsonPath, 'utf8'))

  assert.equal(packageJson.scripts.test, 'node --test')
  assert.equal(packageJson.scripts.dev, 'vite')
  assert.match(packageJson.scripts.build, /tsc --noEmit/)
  assert.equal(packageJson.scripts['test:e2e'], 'playwright test')
  assert.ok(packageJson.dependencies.react)
  assert.ok(packageJson.dependencies['react-dom'])
  assert.ok(packageJson.devDependencies.vite)
  assert.ok(packageJson.devDependencies['@vitejs/plugin-react'])
  assert.ok(packageJson.devDependencies.typescript)
  assert.ok(packageJson.devDependencies.vitest)
  assert.ok(packageJson.devDependencies['@playwright/test'])
  assert.ok(packageJson.devDependencies['@testing-library/react'])
})

test('App is a TSX React component placeholder', async () => {
  const appPath = new URL('../src/App.tsx', import.meta.url)
  const source = await readFile(appPath, 'utf8')

  assert.match(source, /import type \{ReactElement\} from 'react'/)
  assert.match(source, /export function App\(\): ReactElement/)
  assert.match(source, /return \(/)
  assert.match(source, /<main aria-labelledby="app-title">/)
  assert.match(source, /Phoenix REST API/)
})

test('web scaffold exposes the generated API client placeholder path', async () => {
  const clientPath = new URL('../src/api/client.ts', import.meta.url)
  const source = await readFile(clientPath, 'utf8')

  assert.match(source, /export type ApiClientPlaceholder/)
  assert.match(source, /createApiClient/)
})
