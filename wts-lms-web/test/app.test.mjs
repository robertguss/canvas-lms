import test from 'node:test'
import assert from 'node:assert/strict'
import {readFile} from 'node:fs/promises'

test('package metadata declares the deterministic React Vite TypeScript scaffold', async () => {
  const packageJsonPath = new URL('../package.json', import.meta.url)
  const packageJson = JSON.parse(await readFile(packageJsonPath, 'utf8'))

  assert.equal(packageJson.scripts.test, 'node --test')
  assert.equal(packageJson.scripts.dev, 'vite')
  assert.match(packageJson.scripts.build, /tsc --noEmit/)
  assert.equal(packageJson.scripts['test:e2e'], 'node test/e2e.test.mjs')
  assert.equal(packageJson.scripts.axe, 'node test/axe.test.mjs')
  assert.ok(packageJson.dependencies.react)
  assert.ok(packageJson.dependencies['react-dom'])
  assert.ok(packageJson.devDependencies.vite)
  assert.ok(packageJson.devDependencies['@vitejs/plugin-react'])
  assert.ok(packageJson.devDependencies.typescript)
  assert.ok(packageJson.devDependencies.vitest)
  assert.ok(packageJson.devDependencies['@playwright/test'])
  assert.ok(packageJson.devDependencies['@testing-library/react'])
})

test('App is a TSX React component for WTS coursework workflows', async () => {
  const appPath = new URL('../src/App.tsx', import.meta.url)
  const source = await readFile(appPath, 'utf8')

  assert.match(source, /import type \{ReactElement\} from 'react'/)
  assert.match(source, /export function App\(\): ReactElement/)
  assert.match(source, /return \(/)
  assert.match(source, /<main aria-labelledby="app-title"/)
  assert.match(source, /WTS Core Coursework workspace/)
  assert.match(source, /Student workflow/)
  assert.match(source, /Teacher workflow/)
  assert.match(source, /Admin workflow/)
})

test('web state exposes deterministic fixture-backed workflows', async () => {
  const clientPath = new URL('../src/api/client.ts', import.meta.url)
  const source = await readFile(clientPath, 'utf8')

  assert.match(source, /export const wtsWorkflowState/)
  assert.match(source, /createApiClient/)
  assert.match(source, /getCourseForRole/)
  assert.match(source, /Core Theology Seminar/)
})
