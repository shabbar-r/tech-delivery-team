# Known issues (not bugs)

Documented cases where client-reported symptoms are not platform defects.
Check here before treating a report as a new backlog item.

---

## KI-004: API calls fail with 401 after ~60 minutes of continuous use

**Symptom:** A long-running client process starts getting `401 Unauthorized`
on API calls after roughly an hour, and works again immediately after a
restart.

**Cause:** Not a platform defect. Access tokens issued by the platform
expire after 3600 seconds (1 hour) by design — see API docs,
"Authentication → Token lifetime". Clients are expected to refresh the
access token using the `refresh_token` grant before it expires. A client
that caches the initial token and never refreshes it will see exactly this
symptom: works for ~60 minutes, then every call 401s until a fresh token is
obtained (which a full restart does implicitly).

**Guidance to give the client:** Implement a token refresh ahead of the
3600s expiry (a refresh at ~3000s is a safe margin) rather than relying on a
process restart. Link them to the auth flow docs.

**Status:** Working as designed. Not tracked in the backlog.

---

## KI-002: "Missing" webhook events after a plan/tier change

**Symptom:** Client reports that webhook events stopped arriving after they
changed their subscription tier.

**Cause:** Not a platform defect. Webhook event types are scoped per tier;
downgrading (or in some cases upgrading) a plan changes which event types
are enabled and requires re-saving the webhook subscription for the new
event list to take effect. The old subscription silently keeps its previous
event list until it's re-saved.

**Guidance to give the client:** Have them open Settings → Webhooks and
re-save their existing subscription (no need to delete/recreate) after any
plan change.

**Status:** Working as designed. Not tracked in the backlog.
