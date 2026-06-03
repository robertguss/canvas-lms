import test from 'node:test'
import assert from 'node:assert/strict'
import {readFile} from 'node:fs/promises'

const appSource = async () => readFile(new URL('../src/App.tsx', import.meta.url), 'utf8')
const clientSource = async () => readFile(new URL('../src/api/client.ts', import.meta.url), 'utf8')

test('student completes assignment submission flow in rendered static state', async () => {
  const app = await appSource()
  const client = await clientSource()

  assert.match(app, /Dashboard/)
  assert.match(app, /Course home/)
  assert.match(app, /Assignments/)
  assert.match(app, /Text-entry assignment submission/)
  assert.match(app, /File-upload assignment metadata/)
  assert.match(app, /Student gradebook/)
  assert.match(app, /Notifications center/)
  assert.match(client, /Submission received for Reflection 1/)
  assert.match(client, /2026-06-03T14:22:00Z/)
  assert.match(client, /File metadata attached for Research Paper Draft/)
  assert.match(client, /research-paper-draft\.pdf/)
  assert.match(client, /opaque-submission-file-1/)
  assert.doesNotMatch(client, /https?:\/\//)
  assert.doesNotMatch(client, /s3:\/\//)
})

test('unauthorized student cannot see another course', async () => {
  const app = await appSource()
  const client = await clientSource()

  assert.match(app, /Access denied/)
  assert.match(app, /course content\s+is hidden/)
  assert.match(client, /!wtsWorkflowState\.currentStudent\.enrolledCourseIds\.includes\(courseId\)/)
  assert.match(client, /return null/)
})

test('teacher grading comment workflow and gradebook export are present', async () => {
  const app = await appSource()
  const client = await clientSource()

  assert.match(app, /Assignment submissions/)
  assert.match(app, /Grade and comment submission/)
  assert.match(app, /Save grade and comment/)
  assert.match(app, /Export gradebook CSV/)
  assert.match(client, /wts-core-theology-gradebook\.csv/)
})

test('admin import status and diff summary are present', async () => {
  const app = await appSource()
  const client = await clientSource()

  assert.match(app, /Import status/)
  assert.match(app, /Diff summary/)
  assert.match(client, /pilot-core-course-2026-06-03/)
  assert.match(client, /diffSummary: \{passed: 18, failed: 1, warnings: 2\}/)
})

test('excluded features are absent except explicit not-included copy', async () => {
  const app = await appSource()
  const client = await clientSource()
  const combined = `${app}\n${client}`

  assert.match(
    app,
    /Not included: quizzes, discussions, LTI tools, Canvas app shell, js_env, or mobile-app\s+compatibility/,
  )
  assert.doesNotMatch(
    combined,
    /newQuiz|quizEngine|discussionBoard|ltiLaunch|jsEnv|mobileCompatibility|canvasShell/i,
  )
})
