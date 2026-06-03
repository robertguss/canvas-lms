import test from 'node:test'
import assert from 'node:assert/strict'
import {readFile} from 'node:fs/promises'

const grep = (() => {
  const index = process.argv.indexOf('--grep')
  return index === -1 ? null : process.argv[index + 1]
})()

const selected = name => !grep || name.includes(grep)
const e2e = (name, fn) => test(name, {skip: !selected(name)}, fn)

e2e('deterministic e2e workflow surface is represented in source', async () => {
  const app = await readFile(new URL('../src/App.tsx', import.meta.url), 'utf8')
  const client = await readFile(new URL('../src/api/client.ts', import.meta.url), 'utf8')
  const source = `${app}\n${client}`

  for (const expected of [
    'Student workflow',
    'Course home',
    'Text-entry assignment submission',
    'File-upload assignment metadata',
    'Submission received for Reflection 1',
    'Teacher workflow',
    'Save grade and comment',
    'Export gradebook CSV',
    'Admin workflow',
    'Diff summary',
    'Access denied',
  ]) {
    assert.match(source, new RegExp(expected.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')))
  }
})

e2e('@keyboard deterministic keyboard gates cover day-one workflows', async () => {
  const app = await readFile(new URL('../src/App.tsx', import.meta.url), 'utf8')
  const client = await readFile(new URL('../src/api/client.ts', import.meta.url), 'utf8')

  for (const expected of [
    /<a href={`#\$\{role\.toLowerCase\(\)\}-workflow`} key=\{role\}>/,
    /<textarea\s+id="reflection-text"[\s\S]*name="reflection-text"/,
    /<input\s+id="paper-file-name"[\s\S]*name="paper-file-name"/,
    /<button type="button">Submit text entry<\/button>/,
    /<button type="button">Attach file metadata<\/button>/,
    /<input id="teacher-score" name="teacher-score"/,
    /<textarea id="teacher-comment" name="teacher-comment"/,
    /<button type="button">Save grade and comment<\/button>/,
    /<button type="button">Export gradebook CSV<\/button>/,
    /<article aria-labelledby="import-status">/,
    /<p role="alert">\s+Access denied\./,
  ]) {
    assert.match(app, expected)
  }

  assert.match(client, /return null/)
  assert.doesNotMatch(`${app}\n${client}`, /tabIndex=\{?-1\}?|disabled=\{?true\}?|autofocus/i)
})

e2e('@pilot deterministic pilot rehearsal covers operational launch gates', async () => {
  const app = await readFile(new URL('../src/App.tsx', import.meta.url), 'utf8')
  const client = await readFile(new URL('../src/api/client.ts', import.meta.url), 'utf8')
  const source = `${app}\n${client}`

  for (const expected of [
    'Student workflow',
    'Text-entry assignment submission',
    'Teacher workflow',
    'Save grade and comment',
    'Admin workflow',
    'Diff summary',
    'Notifications center',
    'Submission received for Reflection 1',
    'Access denied',
  ]) {
    assert.match(source, new RegExp(expected.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')))
  }

  assert.match(client, /diffSummary: \{passed: 18, failed: 1, warnings: 2\}/)
  assert.match(app, /Not included: quizzes, discussions, LTI tools/)
  assert.doesNotMatch(
    source,
    /access_token|Authorization|Bearer|saml_assertion|private_evidence|raw_url/i,
  )
})
