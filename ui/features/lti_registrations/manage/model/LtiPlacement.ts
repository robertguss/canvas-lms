/*
 * Copyright (C) 2023 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import * as z from 'zod'

// TODO: this list is duplicated in ui/features/external_apps/react/components/ExternalToolPlacementList.jsx
// We should consolidate some of the lti "models" into a shared package that both features depend on

/**
 * Within an { @see LtiImsRegistration }, all Canvas-specific placements are prefixed by this string.
 * Note that the { @see LtiToolConfiguration } does *not* have this prefix, as any placements within that
 * object are known to be Canvas-specific already.
 */
export const canvasPlacementPrefix = 'https://canvas.instructure.com/lti/'

/**
 * A record where the keys are placement identifiers
 * and the values are the internationalized human-readable
 * names of those placements
 */
export const LtiPlacements = {
  /**
   * Account-level navigation
   */
  AccountNavigation: 'account_navigation',
  /**
   * Renders a frame on the assignment edit page, under
   * the native assignment options
   */
  AssignmentEdit: 'assignment_edit',
  /**
   * Appears under the "External Tool" submission type for assignments
   */
  AssignmentSelection: 'assignment_selection',
  /**
   * Renders a frame under every assignment, when viewing
   */
  AssignmentView: 'assignment_view',
  SimilarityDetection: 'similarity_detection',
  /**
   * Appears as an option in the Assignment ellipsis (for every assignment)
   * when viewing the list of course assignments
   */
  AssignmentMenu: 'assignment_menu',
  /**
   * Appears as an option in the Assignment ellipsis menu when viewing an assignment
   * Like course_assignments_menu, but launches into a tray modal
   */
  AssignmentIndexMenu: 'assignment_index_menu',
  /**
   * Appears as an option in the Assignment Group ellipsis menu when viewing the list of course assigments
   */
  AssignmentGroupMenu: 'assignment_group_menu',
  Collaboration: 'collaboration',
  ConferenceSelection: 'conference_selection',
  /**
   * Appears as an option in the Assignment ellipsis menu when viewing an assignment
   */
  CourseAssignmentsMenu: 'course_assignments_menu',
  /**
   * Appears in the right side-bar of the Course home page
   */
  CourseHomeSubNavigation: 'course_home_sub_navigation',
  /**
   * Appears in the left sidebar of a Course
   */
  CourseNavigation: 'course_navigation',
  /**
   * Appears in the right sidebar of the Course settings page
   */
  CourseSettingsSubNavigation: 'course_settings_sub_navigation',
  /**
   * Appears in the ellipsis menu on a Discussion Topic page,
   * and also in the ellipsis menu on each Discussion Topic
   * on the Discussion Topic Index page
   */
  DiscussionTopicMenu: 'discussion_topic_menu',
  /**
   * Appears in the top-level ellipsis menu on the Discussion Topic Index page
   */
  DiscussionTopicIndexMenu: 'discussion_topic_index_menu',
  /**
   * Appears as an option in the RCE toolbar
   */
  EditorButton: 'editor_button',
  FileMenu: 'file_menu',
  FileIndexMenu: 'file_index_menu',
  /**
   * Appears in the global left sidebar
   */
  GlobalNavigation: 'global_navigation',
  /**
   * Appears on the submission page for an assigment.
   * Users can use it to submit an assignment.
   */
  HomeworkSubmission: 'homework_submission',
  LinkSelection: 'link_selection',
  MigrationSelection: 'migration_selection',
  ModuleGroupMenu: 'module_group_menu',
  ModuleIndexMenu: 'module_index_menu',
  ModuleIndexMenuModal: 'module_index_menu_modal',
  ModuleMenu: 'module_menu',
  ModuleMenuModal: 'module_menu_modal',
  PostGrades: 'post_grades',
  QuizMenu: 'quiz_menu',
  QuizIndexMenu: 'quiz_index_menu',
  SubmissionTypeSelection: 'submission_type_selection',
  StudentContextCard: 'student_context_card',
  ToolConfiguration: 'tool_configuration',
  TopNavigation: 'top_navigation',
  UserNavigation: 'user_navigation',
  WikiPageMenu: 'wiki_page_menu',
  WikiIndexMenu: 'wiki_index_menu',
} as const

export const AllLtiPlacements = [
  LtiPlacements.AccountNavigation,
  LtiPlacements.AssignmentEdit,
  LtiPlacements.AssignmentSelection,
  LtiPlacements.AssignmentView,
  LtiPlacements.SimilarityDetection,
  LtiPlacements.AssignmentMenu,
  LtiPlacements.AssignmentIndexMenu,
  LtiPlacements.AssignmentGroupMenu,
  LtiPlacements.Collaboration,
  LtiPlacements.ConferenceSelection,
  LtiPlacements.CourseAssignmentsMenu,
  LtiPlacements.CourseHomeSubNavigation,
  LtiPlacements.CourseNavigation,
  LtiPlacements.CourseSettingsSubNavigation,
  LtiPlacements.DiscussionTopicMenu,
  LtiPlacements.DiscussionTopicIndexMenu,
  LtiPlacements.EditorButton,
  LtiPlacements.FileMenu,
  LtiPlacements.FileIndexMenu,
  LtiPlacements.GlobalNavigation,
  LtiPlacements.HomeworkSubmission,
  LtiPlacements.LinkSelection,
  LtiPlacements.MigrationSelection,
  LtiPlacements.ModuleGroupMenu,
  LtiPlacements.ModuleIndexMenu,
  LtiPlacements.ModuleIndexMenuModal,
  LtiPlacements.ModuleMenu,
  LtiPlacements.ModuleMenuModal,
  LtiPlacements.PostGrades,
  LtiPlacements.QuizMenu,
  LtiPlacements.QuizIndexMenu,
  LtiPlacements.SubmissionTypeSelection,
  LtiPlacements.StudentContextCard,
  LtiPlacements.ToolConfiguration,
  LtiPlacements.TopNavigation,
  LtiPlacements.UserNavigation,
  LtiPlacements.WikiPageMenu,
  LtiPlacements.WikiIndexMenu,
] as const

export const ZLtiPlacement = z.enum(AllLtiPlacements)
export type LtiPlacement = z.infer<typeof ZLtiPlacement>

export const LtiPlacementsWithIcons = [
  LtiPlacements.GlobalNavigation,
  LtiPlacements.CourseHomeSubNavigation,
  LtiPlacements.AssignmentIndexMenu,
  LtiPlacements.CourseSettingsSubNavigation,
  LtiPlacements.DiscussionTopicMenu,
  LtiPlacements.DiscussionTopicIndexMenu,
  LtiPlacements.EditorButton,
  LtiPlacements.FileIndexMenu,
] as const

export type LtiPlacementWithIcon = (typeof LtiPlacementsWithIcons)[number]

export const isLtiPlacement = (placement: unknown): placement is LtiPlacement => {
  return AllLtiPlacements.includes(placement as LtiPlacement)
}
