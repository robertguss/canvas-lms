export type Role = 'Student' | 'Teacher' | 'Admin'

export type LearnerSubmission = {
  assignmentId: string
  kind: 'text-entry' | 'file-upload'
  submittedAt: string
  confirmation: string
  text?: string
  file?: {
    name: string
    sizeLabel: string
    storageReference: string
  }
}

export type Assignment = {
  id: string
  title: string
  dueAt: string
  points: number
  type: 'text-entry' | 'file-upload' | 'no-submission'
  prompt: string
}

export type WtsCourse = {
  id: string
  title: string
  term: string
  syllabus: string
  modules: string[]
  pages: string[]
  files: Array<{name: string; description: string; storageReference: string}>
  announcements: Array<{title: string; postedAt: string; summary: string}>
  assignments: Assignment[]
}

export type GradebookRow = {
  learner: string
  assignment: string
  score: string
  feedback: string
}

export type WtsWorkflowState = {
  roles: Role[]
  currentStudent: {
    name: string
    enrolledCourseIds: string[]
    notifications: Array<{title: string; detail: string; unread: boolean}>
    submissions: LearnerSubmission[]
    grades: GradebookRow[]
  }
  teacher: {
    name: string
    reviewQueue: Array<{student: string; assignment: string; submittedAt: string; status: string}>
    gradebook: GradebookRow[]
    exportFileName: string
  }
  admin: {
    importBatch: string
    status: string
    diffSummary: {passed: number; failed: number; warnings: number}
  }
  courses: WtsCourse[]
  unauthorizedCourse: WtsCourse
}

export const wtsWorkflowState: WtsWorkflowState = {
  roles: ['Student', 'Teacher', 'Admin'],
  currentStudent: {
    name: 'WTS Learner',
    enrolledCourseIds: ['core-101'],
    notifications: [
      {
        title: 'Announcement posted',
        detail: 'Seminar reading plan is ready for Core Theology.',
        unread: true,
      },
      {
        title: 'Grade released',
        detail: 'Reflection 1 feedback is available in the WTS gradebook.',
        unread: false,
      },
    ],
    submissions: [
      {
        assignmentId: 'reflection-1',
        kind: 'text-entry',
        submittedAt: '2026-06-03T14:22:00Z',
        confirmation: 'Submission received for Reflection 1',
        text: 'I traced the assigned doctrine theme through the module readings.',
      },
      {
        assignmentId: 'paper-upload',
        kind: 'file-upload',
        submittedAt: '2026-06-03T15:04:00Z',
        confirmation: 'File metadata attached for Research Paper Draft',
        file: {
          name: 'research-paper-draft.pdf',
          sizeLabel: '412 KB',
          storageReference: 'opaque-submission-file-1',
        },
      },
    ],
    grades: [
      {
        learner: 'WTS Learner',
        assignment: 'Reflection 1',
        score: '9 / 10',
        feedback: 'Clear thesis.',
      },
      {
        learner: 'WTS Learner',
        assignment: 'Research Paper Draft',
        score: 'Pending',
        feedback: 'Awaiting review.',
      },
    ],
  },
  teacher: {
    name: 'WTS Faculty',
    reviewQueue: [
      {
        student: 'WTS Learner',
        assignment: 'Reflection 1',
        submittedAt: '2026-06-03T14:22:00Z',
        status: 'Ready to grade',
      },
      {
        student: 'WTS Learner',
        assignment: 'Research Paper Draft',
        submittedAt: '2026-06-03T15:04:00Z',
        status: 'File metadata attached',
      },
    ],
    gradebook: [
      {
        learner: 'WTS Learner',
        assignment: 'Reflection 1',
        score: '9 / 10',
        feedback: 'Clear thesis.',
      },
      {
        learner: 'WTS Learner',
        assignment: 'Research Paper Draft',
        score: 'Needs grade',
        feedback: 'Teacher comment pending.',
      },
    ],
    exportFileName: 'wts-core-theology-gradebook.csv',
  },
  admin: {
    importBatch: 'pilot-core-course-2026-06-03',
    status: 'Validated with fixture diff',
    diffSummary: {passed: 18, failed: 1, warnings: 2},
  },
  courses: [
    {
      id: 'core-101',
      title: 'Core Theology Seminar',
      term: 'Summer Pilot 2026',
      syllabus: 'Weekly reading, seminar participation, reflection writing, and a research draft.',
      modules: [
        'Orientation and covenant learning',
        'Doctrine reading sequence',
        'Research workshop',
      ],
      pages: ['Welcome to WTS coursework', 'Reflection writing guide'],
      files: [
        {
          name: 'seminar-reading-list.pdf',
          description: 'Reading list metadata only',
          storageReference: 'opaque-course-file-1',
        },
      ],
      announcements: [
        {
          title: 'Seminar begins Monday',
          postedAt: '2026-06-01',
          summary: 'Bring the orientation reading notes.',
        },
      ],
      assignments: [
        {
          id: 'reflection-1',
          title: 'Reflection 1',
          dueAt: '2026-06-07T23:59:00Z',
          points: 10,
          type: 'text-entry',
          prompt: 'Submit a concise theological reflection in the text box.',
        },
        {
          id: 'paper-upload',
          title: 'Research Paper Draft',
          dueAt: '2026-06-14T23:59:00Z',
          points: 30,
          type: 'file-upload',
          prompt: 'Attach file metadata for the draft; raw object storage URLs stay hidden.',
        },
      ],
    },
  ],
  unauthorizedCourse: {
    id: 'core-999',
    title: 'Restricted Faculty Archive',
    term: 'Archived',
    syllabus: 'Restricted content must not render for unauthorized students.',
    modules: ['Restricted module'],
    pages: ['Restricted page'],
    files: [
      {
        name: 'restricted.pdf',
        description: 'Restricted',
        storageReference: 'opaque-restricted-file',
      },
    ],
    announcements: [
      {title: 'Restricted announcement', postedAt: '2026-06-01', summary: 'Restricted'},
    ],
    assignments: [],
  },
}

export function getCourseForRole(courseId: string, role: Role): WtsCourse | null {
  if (role === 'Admin' || role === 'Teacher') {
    return wtsWorkflowState.courses.find(course => course.id === courseId) ?? null
  }

  if (!wtsWorkflowState.currentStudent.enrolledCourseIds.includes(courseId)) {
    return null
  }

  return wtsWorkflowState.courses.find(course => course.id === courseId) ?? null
}

export function createApiClient(baseUrl: string) {
  return {
    baseUrl,
    getWorkflowState: () => wtsWorkflowState,
    getCourseForRole,
  }
}
