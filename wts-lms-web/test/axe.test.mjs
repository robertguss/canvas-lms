import test from 'node:test'
import assert from 'node:assert/strict'
import {readFile} from 'node:fs/promises'

test('deterministic accessibility basics exist for core workflows', async () => {
  const app = await readFile(new URL('../src/App.tsx', import.meta.url), 'utf8')

  assert.match(app, /<main aria-labelledby="app-title"/)
  assert.match(app, /<nav aria-label="Workflow roles"/)
  assert.match(app, /<h1 id="app-title">/)
  assert.match(app, /<h2 id="student-workflow">Student workflow<\/h2>/)
  assert.match(app, /<h2 id="teacher-workflow">Teacher workflow<\/h2>/)
  assert.match(app, /<h2 id="admin-workflow">Admin workflow<\/h2>/)
  assert.match(app, /<label htmlFor="reflection-text">Reflection text<\/label>/)
  assert.match(app, /<label htmlFor="paper-file-name">File name<\/label>/)
  assert.match(app, /<label htmlFor="teacher-score">Score<\/label>/)
  assert.match(app, /<label htmlFor="teacher-comment">Teacher comment<\/label>/)
  assert.match(app, /<button type="button">Submit text entry<\/button>/)
  assert.match(app, /<button type="button">Attach file metadata<\/button>/)
  assert.match(app, /<button type="button">Save grade and comment<\/button>/)
  assert.match(app, /<button type="button">Export gradebook CSV<\/button>/)
  assert.match(app, /role="status"/)
  assert.match(app, /role="alert"/)
})

test('deterministic accessibility gate covers day-one workflow regions', async () => {
  const app = await readFile(new URL('../src/App.tsx', import.meta.url), 'utf8')

  for (const expected of [
    /<form aria-label="Text-entry assignment submission">/,
    /<form aria-label="File-upload assignment metadata">/,
    /<form aria-label="Grade and comment submission">/,
    /<article aria-labelledby="import-status">/,
    /<section aria-labelledby="access-denied">/,
    /<p role="alert">\s+Access denied\./,
  ]) {
    assert.match(app, expected)
  }

  assert.doesNotMatch(app, /aria-hidden="true"[^>]*(button|input|textarea|a)/)
  assert.doesNotMatch(app, /tabIndex=\{?-1\}?/)
})
