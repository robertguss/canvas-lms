# Canvas Migration Source Inventory

Task 2 proves the migration input strategy for one representative active-course pilot fixture before importer implementation starts. This inventory is intentionally source-focused: it names the expected source for each WTS Core Coursework entity family, the fallback when the primary source is incomplete, and the blocker or real-sample gate that keeps Tasks 5, 8, and 11 from proceeding on mocked-only data.

## Gate For Downstream Tasks

- BLOCKER: Tasks 5, 8, and 11 must not proceed to production-quality schema, importer, file, submission, or gradebook implementation from mocked-only data prohibited inputs.
- BLOCKER: Each pilot entity below requires a real sanitized sample from one active course, or a recorded owner and next action for the missing source, before the downstream task can mark its production path unblocked.
- real sanitized sample means data exported from Canvas/WTS systems and scrubbed of student, faculty, course, file, grade, submission, comment, and identity details before entering this repository.
- The placeholder files under `wts-lms-api/test/fixtures/canvas_sample/pilot_course/` are non-sensitive shape markers only. They do not satisfy the real sanitized sample gate.
- DAP provides table-like records and metadata for Canvas Data 2 tables. DAP has attachment records and metadata, but this task found no official proof that DAP provides file bytes. File bytes must be collected through Canvas REST API URLs, course export packages, or explicit file download manifests unless official documentation later proves otherwise.

## Pilot Entity Source Matrix

| Entity family | Primary source | Required DAP or source tables/endpoints | Fallback/source limitation note | Gate for Tasks 5, 8, 11 |
| --- | --- | --- | --- | --- |
| users | SIS, DAP | SIS user extract; DAP `users`, `pseudonyms`, `communication_channels` metadata when available | SIS/Registrar remains authoritative for academic identity. DAP/REST can map legacy Canvas user IDs but must not override SIS status. | BLOCKER: provide real sanitized sample for Student, Teacher, and Admin identities plus legacy Canvas user ID mappings. |
| terms | SIS, DAP | SIS term extract; DAP `enrollment_terms` | SIS is primary for term names, dates, and active status. DAP is a Canvas mapping/cross-check source. | BLOCKER: provide real sanitized sample with current pilot term and Canvas term ID. |
| courses | SIS, DAP, REST | SIS course extract; DAP `courses`; Canvas REST course detail for syllabus/settings used by WTS | SIS owns course identity and offering status. REST/course export may be needed for syllabus/body fields not represented as needed in DAP. | BLOCKER: provide real sanitized sample for one active course before course schema/import work leaves fixture mode. |
| sections | SIS, DAP | SIS section extract; DAP `course_sections` | SIS owns section membership and active status. DAP preserves Canvas section IDs for mapping. | BLOCKER: provide real sanitized sample with every active pilot section and Canvas section ID. |
| enrollments | SIS, DAP | SIS enrollment extract; DAP `enrollments` | SIS add/drop state is authoritative. DAP helps audit Canvas role/workflow state and legacy enrollment IDs. | BLOCKER: provide real sanitized sample for active/dropped Student and Teacher enrollment cases. |
| modules | DAP, REST, course export | DAP `context_modules`, `content_tags`; Canvas REST modules/items; course export module metadata | DAP provides module records and item metadata. REST/export may be needed for display ordering and item URLs as Canvas presents them. | BLOCKER: provide real sanitized sample for at least one module containing a page, assignment, and file item. |
| pages | DAP, REST, course export | DAP `wiki_pages`/wiki metadata; Canvas REST pages; course export HTML/resources | DAP can provide page records/metadata. REST or course export is the fallback for normalized HTML body fidelity and embedded file links. | BLOCKER: provide real sanitized sample for page body, title, workflow state, and legacy Canvas page ID. |
| announcements | DAP, REST, course export | DAP `discussion_topics`/announcement metadata when scoped as announcements; Canvas REST announcements; course export discussion/announcement resources | Day-one preserves announcements but excludes broad discussions. Filter to Canvas announcement records only. | BLOCKER: provide real sanitized sample with at least one announcement or record an explicit no-announcement pilot gap. |
| assignments | DAP, REST, course export | DAP `assignments`, `assignment_overrides`; Canvas REST assignments; course export assignment metadata | DAP covers core assignment records, dates, points, submission types, group, description metadata. REST/export validates runtime presentation and HTML body fidelity. | BLOCKER: provide real sanitized sample for text-entry, file-upload, and no-submission assignments or remove missing types from pilot scope. |
| assignment groups | DAP, REST | DAP `assignment_groups`; Canvas REST assignment groups | DAP includes group name, weight, position, workflow state, and rules metadata. REST cross-checks Canvas gradebook presentation. | BLOCKER: provide real sanitized sample for weighted and unweighted group behavior used by the pilot gradebook. |
| submissions | DAP, REST, file download | DAP `submissions`, `submission_versions`, `attachment_associations`; Canvas REST submissions and submission attachments | DAP provides table-like submission records and metadata. Text bodies and attachment associations must be verified against REST; file bytes require REST/file download. | BLOCKER: provide real sanitized sample for submitted, missing, late, graded, and file-upload submissions before Task 8/11 production implementation. |
| grades | DAP, REST | DAP `scores`, `submission_scores`, `enrollment_states`, `submissions`; Canvas REST gradebook/submission views | Grade calculation must follow `gradebook_rules.md`. DAP/REST are source inputs, not acceptance by themselves; diff must match final percentage and letter display. | BLOCKER: provide real sanitized sample with points, weighted groups, posted grade, hidden/missing/late examples, and CSV comparison. |
| attachments/files | DAP, REST, course export, file download | DAP `attachments`, `folders`, `attachment_associations`; Canvas REST files; course export resource files; file download manifest | DAP gives metadata such as ID, context, filename, size, content type, hash/uuid when present, but file bytes require REST, course export, or file download unless proven otherwise. | BLOCKER: provide real sanitized sample manifest with checksum/byte-size for every pilot course file and submission attachment. |
| comments | DAP, REST | DAP `submission_comments`/comment metadata where available; Canvas REST submission comments | Comments are FERPA-sensitive. Use REST to verify author, timestamp, visibility, and grading-comment semantics when DAP metadata is insufficient. | BLOCKER: provide real sanitized sample with scrubbed student/teacher comments and grading comments, or record pilot course has none. |
| legacy Canvas ID mappings | Mixed | Stable Canvas IDs from DAP tables, REST endpoints, course export identifiers, and file download manifest rows | Each Phoenix record imported from Canvas keeps a legacy Canvas ID mapping. SIS-owned rows also keep SIS IDs. Mixed sources must reconcile to one mapping table. | BLOCKER: provide real sanitized sample mapping for users, terms, courses, sections, enrollments, modules, pages, announcements, assignments, assignment groups, submissions, grades, attachments, comments. |

## Fixture Expectations

The Task 2 fixture tree uses sanitized placeholders so later tests can depend on directory and manifest shape without importing private records. Required real inputs are recorded as gates rather than faked values.

| Fixture source | Purpose | Required real-sample replacement |
| --- | --- | --- |
| `dap/manifest.json` | Lists DAP Canvas namespace tables expected for the pilot course and marks placeholders as sanitized. | Real sanitized DAP extracts for every entity table in the matrix. |
| `rest/manifest.json` | Lists Canvas REST endpoints needed to verify runtime semantics and source gaps. | Real sanitized REST responses with PII/body/file values scrubbed. |
| `course_export/manifest.json` | Lists course export package metadata needed for content body/resources verification. | Real sanitized course export metadata and scrubbed HTML/resource references. |
| `file_download/manifest.json` | Lists file byte acquisition and checksum expectations. | Real sanitized file download manifest with checksums/byte sizes and no private file bytes committed unless explicitly approved. |

## Open Blockers

- BLOCKER: No real sanitized sample has been committed for the representative active course yet. Owner: migration lead. Next action: export and sanitize one active WTS Core Coursework course into the fixture shape, or document why the course cannot be used.
- BLOCKER: File payload verification cannot rely on DAP alone. Owner: migration lead. Next action: prove Canvas REST/course export/file download path for each pilot course file and submission attachment, then update `file_download/manifest.json` with checksums and byte sizes.
- BLOCKER: Tasks 5, 8, and 11 remain blocked from production-quality implementation if they only consume mocked placeholders; mocked-only data prohibited until real sanitized sample evidence exists or an explicit owner/next action is recorded here.
