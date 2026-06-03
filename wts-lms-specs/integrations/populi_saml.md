# Populi SAML Authentication Contract

## Scope

This contract defines how the WTS Phoenix LMS accepts Populi SAML login assertions and maps them to SIS-synced users. Populi remains the identity provider. The SIS/Registrar feed remains authoritative for users, academic status, roles, courses, sections, terms, and enrollments. Phoenix must not own academic records and must not provide normal local-password auth for Students, Teachers, or Admins.

Phoenix may maintain only application-local session state, audit events, authorization grants derived from SIS records, and operational metadata needed to run the LMS.

## Required SAML Attribute Set

Each Populi assertion accepted by Phoenix must include the following SAML attribute values:

| Field | Required | Contract |
| --- | --- | --- |
| `NameID` | Yes | Stable Populi login identifier for the person. It must not be used alone to create an LMS user. |
| `email` | Yes | Primary institutional email address. It is normalized to lowercase and trimmed before matching. |
| `sis_user_id` | Yes | SIS-owned person identifier. It is the primary matching key and must match exactly one active SIS-synced user row. |
| `first_name` | Yes | Display metadata from Populi. Stored only when the SIS sync has not supplied a fresher value. |
| `last_name` | Yes | Display metadata from Populi. Stored only when the SIS sync has not supplied a fresher value. |

Optional attributes may be logged as raw assertion metadata for troubleshooting only if they do not contain secrets and do not expand LMS authorization. Optional attributes must not create roles, courses, sections, terms, or enrollments.

## User Matching Rules

Phoenix matches a valid assertion in this order:

1. Match `sis_user_id` to exactly one SIS-synced user.
2. Verify the matched user has the same normalized `email` as the assertion.
3. Record the observed `NameID` on the user identity binding if no binding exists.
4. If a binding exists, require the assertion `NameID` to match the bound value for the same `sis_user_id`.

Email is a verification key, not the primary identity key. If `email` matches an existing user but `sis_user_id` is missing, different, or unmatched, Phoenix must reject the login rather than infer identity. If `NameID` matches a prior binding but `sis_user_id` points to a different user, Phoenix must reject the login as an identity conflict.

Phoenix must never auto-provision normal users from a SAML assertion. User records are created, disabled, and updated only by SIS sync.

## Valid Assertion Behavior

A valid assertion is accepted only when all conditions are true:

- The SAML response signature is valid for the configured Populi IdP certificate.
- The assertion audience matches the Phoenix LMS service provider entity ID.
- The assertion destination and recipient match the configured Phoenix ACS endpoint.
- The assertion is within the `NotBefore` and `NotOnOrAfter` validity window with configured clock skew.
- The assertion contains one `NameID`, one `email`, and one `sis_user_id`.
- `sis_user_id` matches exactly one SIS-synced, non-disabled user.
- The matched user has at least one active day-one role: Student, Teacher, or Admin.
- The matched user is allowed by current SIS-owned term, course, section, and enrollment records.

On success, Phoenix creates an application session for the matched user, rotates any existing login nonce or session fixation vector, updates last-login metadata, and writes an audit event.

## Invalid Assertion Behavior

### Missing Attribute

If `NameID`, `email`, or `sis_user_id` is absent, blank, duplicated, or malformed, Phoenix must reject the login before user lookup. The response must not reveal which users exist. The audit event must include `missing attribute` with the missing or malformed attribute names.

### Disabled User

If the SIS-synced user has `disabled = true`, inactive academic status, or an SIS status that forbids LMS access, Phoenix must reject the login with an authorization failure. No session is created. The audit event must include `disabled user`, `sis_user_id`, and the blocking status.

### Unmatched User

If `sis_user_id` does not match a SIS-synced user, Phoenix must reject the login. Phoenix must not create a local user, must not fall back to email-only matching, and must not offer local-password setup. The audit event must include `unmatched user` and the asserted `sis_user_id`.

### Identity Conflict

If `sis_user_id`, `email`, or `NameID` point to inconsistent existing bindings, Phoenix must reject the login and report a security conflict. The conflict must be visible to Admin audit review and operations failure reporting.

## Session Behavior

SAML establishes browser authentication only. Phoenix owns session tokens and revocation, but not the underlying identity.

- Normal login path: Populi SAML redirect and callback only.
- Normal local-password auth: prohibited for Students, Teachers, and Admins.
- Session lifetime: Phoenix sessions expire after 8 hours of idle time and after a 12-hour absolute lifetime, whichever comes first.
- Session authorization: recomputed from current SIS-owned user, role, course, section, term, and enrollment records on each request or from a short-lived authorization cache.
- Disabled user after login: the next authorization check must reject access and revoke active sessions.
- Role or enrollment change after login: access must reflect the newest successful SIS sync, not stale SAML attributes.

## Audit Expectations

Phoenix must write an audit event for every SAML callback attempt. Audit events must include timestamp, request correlation ID, IdP entity ID, outcome, reason code, `sis_user_id` when present, normalized `email` when present, user ID when matched, source IP, user agent, and assertion ID. Audit logs must not store passwords because normal local passwords are not supported, and must not store full raw assertions unless explicitly enabled for short-lived incident debugging.

Required reason codes include `valid assertion`, `missing attribute`, `disabled user`, `unmatched user`, `identity conflict`, `invalid signature`, `invalid audience`, `expired assertion`, and `unsupported role`.

## Implementation Requirements For Later Phoenix Work

- Treat this file as the contract for Task 6 SAML callback tests.
- Use `sis_user_id` as the stable primary external identity key.
- Use `NameID` as an IdP binding verification key.
- Use `email` as a normalized verification key and display/contact field.
- Do not create local-password auth as the normal path.
- Do not let Phoenix create, own, or manually override academic records.
