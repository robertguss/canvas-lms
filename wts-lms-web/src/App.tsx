import type {ReactElement} from 'react'
import {getCourseForRole, wtsWorkflowState} from './api/client'

function formatTimestamp(value: string): string {
  return new Intl.DateTimeFormat('en-US', {
    dateStyle: 'medium',
    timeStyle: 'short',
    timeZone: 'UTC',
  }).format(new Date(value))
}

export function App(): ReactElement {
  const course = getCourseForRole('core-101', 'Student')
  const unauthorizedCourse = getCourseForRole('core-999', 'Student')
  const textSubmission = wtsWorkflowState.currentStudent.submissions.find(
    submission => submission.kind === 'text-entry',
  )
  const fileSubmission = wtsWorkflowState.currentStudent.submissions.find(
    submission => submission.kind === 'file-upload',
  )

  return (
    <main aria-labelledby="app-title" className="wts-coursework-workspace">
      <section aria-labelledby="app-title">
        <p>WTS LMS Phoenix</p>
        <h1 id="app-title">WTS Core Coursework workspace</h1>
        <p>Focused Student, Teacher, and Admin workflows for the WTS pilot.</p>
        <nav aria-label="Workflow roles">
          {wtsWorkflowState.roles.map(role => (
            <a href={`#${role.toLowerCase()}-workflow`} key={role}>
              {role}
            </a>
          ))}
        </nav>
        <p aria-label="Scope exclusions">
          Not included: quizzes, discussions, LTI tools, Canvas app shell, js_env, or mobile-app
          compatibility.
        </p>
      </section>

      <section aria-labelledby="student-workflow" id="student-workflow">
        <h2 id="student-workflow">Student workflow</h2>
        <article aria-labelledby="student-dashboard">
          <h3 id="student-dashboard">Dashboard</h3>
          <p>
            {wtsWorkflowState.currentStudent.name} is enrolled in {course?.title} for {course?.term}
            .
          </p>
        </article>

        {course ? (
          <article aria-labelledby="course-home">
            <h3 id="course-home">Course home</h3>
            <p>{course.syllabus}</p>
            <h4>Modules</h4>
            <ul>
              {course.modules.map(module => (
                <li key={module}>{module}</li>
              ))}
            </ul>
            <h4>Pages</h4>
            <ul>
              {course.pages.map(page => (
                <li key={page}>{page}</li>
              ))}
            </ul>
            <h4>Files</h4>
            <ul>
              {course.files.map(file => (
                <li key={file.storageReference}>
                  {file.name}: {file.description}
                </li>
              ))}
            </ul>
            <h4>Announcements</h4>
            <ul>
              {course.announcements.map(announcement => (
                <li key={announcement.title}>
                  {announcement.title}: {announcement.summary}
                </li>
              ))}
            </ul>
          </article>
        ) : null}

        <article aria-labelledby="assignment-workflow">
          <h3 id="assignment-workflow">Assignments</h3>
          <ul>
            {course?.assignments.map(assignment => (
              <li key={assignment.id}>
                <strong>{assignment.title}</strong>: {assignment.prompt} Due{' '}
                {formatTimestamp(assignment.dueAt)} for {assignment.points} points.
              </li>
            ))}
          </ul>
          <form aria-label="Text-entry assignment submission">
            <label htmlFor="reflection-text">Reflection text</label>
            <textarea
              id="reflection-text"
              name="reflection-text"
              defaultValue={textSubmission?.text}
            />
            <button type="button">Submit text entry</button>
            <p role="status">
              {textSubmission?.confirmation} at{' '}
              {textSubmission ? formatTimestamp(textSubmission.submittedAt) : ''}.
            </p>
          </form>
          <form aria-label="File-upload assignment metadata">
            <label htmlFor="paper-file-name">File name</label>
            <input
              id="paper-file-name"
              name="paper-file-name"
              defaultValue={fileSubmission?.file?.name}
            />
            <button type="button">Attach file metadata</button>
            <p role="status">
              {fileSubmission?.confirmation} at{' '}
              {fileSubmission ? formatTimestamp(fileSubmission.submittedAt) : ''}; stored as{' '}
              {fileSubmission?.file?.storageReference} without raw object storage URLs.
            </p>
          </form>
        </article>

        <article aria-labelledby="student-grades">
          <h3 id="student-grades">Student gradebook</h3>
          <table>
            <caption>Current grades and feedback</caption>
            <thead>
              <tr>
                <th>Assignment</th>
                <th>Score</th>
                <th>Feedback</th>
              </tr>
            </thead>
            <tbody>
              {wtsWorkflowState.currentStudent.grades.map(row => (
                <tr key={row.assignment}>
                  <td>{row.assignment}</td>
                  <td>{row.score}</td>
                  <td>{row.feedback}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </article>

        <article aria-labelledby="notifications-center">
          <h3 id="notifications-center">Notifications center</h3>
          <ul>
            {wtsWorkflowState.currentStudent.notifications.map(notification => (
              <li key={notification.title}>
                {notification.unread ? 'Unread' : 'Read'}: {notification.title} -{' '}
                {notification.detail}
              </li>
            ))}
          </ul>
        </article>
      </section>

      <section aria-labelledby="access-denied">
        <h2 id="access-denied">Unauthorized course state</h2>
        {unauthorizedCourse ? null : (
          <p role="alert">
            Access denied. This student is not enrolled in the requested course, so course content
            is hidden.
          </p>
        )}
      </section>

      <section aria-labelledby="teacher-workflow" id="teacher-workflow">
        <h2 id="teacher-workflow">Teacher workflow</h2>
        <article aria-labelledby="submission-review">
          <h3 id="submission-review">Assignment submissions</h3>
          <ul>
            {wtsWorkflowState.teacher.reviewQueue.map(item => (
              <li key={`${item.student}-${item.assignment}`}>
                {item.student} - {item.assignment} - {item.status} at{' '}
                {formatTimestamp(item.submittedAt)}
              </li>
            ))}
          </ul>
          <form aria-label="Grade and comment submission">
            <label htmlFor="teacher-score">Score</label>
            <input id="teacher-score" name="teacher-score" defaultValue="9" />
            <label htmlFor="teacher-comment">Teacher comment</label>
            <textarea id="teacher-comment" name="teacher-comment" defaultValue="Clear thesis." />
            <button type="button">Save grade and comment</button>
          </form>
        </article>
        <article aria-labelledby="teacher-gradebook">
          <h3 id="teacher-gradebook">Gradebook and export</h3>
          <p>CSV export surface: {wtsWorkflowState.teacher.exportFileName}</p>
          <button type="button">Export gradebook CSV</button>
        </article>
      </section>

      <section aria-labelledby="admin-workflow" id="admin-workflow">
        <h2 id="admin-workflow">Admin workflow</h2>
        <article aria-labelledby="import-status">
          <h3 id="import-status">Import status</h3>
          <p>
            Batch {wtsWorkflowState.admin.importBatch}: {wtsWorkflowState.admin.status}.
          </p>
          <p>
            Diff summary: {wtsWorkflowState.admin.diffSummary.passed} passed,{' '}
            {wtsWorkflowState.admin.diffSummary.failed} failed,{' '}
            {wtsWorkflowState.admin.diffSummary.warnings} warnings.
          </p>
        </article>
      </section>
    </main>
  )
}
