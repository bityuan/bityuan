# Security policy

## Reporting a vulnerability

**Do not open a public issue for a security problem.**

Use GitHub's private vulnerability reporting: open the **Security** tab of this
repository and choose **Report a vulnerability**. The report is visible to the
maintainers only, and the discussion, the fix and the eventual advisory stay
there.

If you cannot use that form, reach the maintainers through
<https://www.bityuan.com> and say that you have a security report.

## What to expect

This is an open-source project, and security reports are handled by its maintainers.
A confirmed report is fixed in a release, and an advisory is published with the fix
when the impact warrants one. Tell us in the report if you would rather stay
anonymous.

## Scope

This repository is the chain binary and its configuration. Vulnerabilities in
[chain33](https://github.com/33cn/chain33) or [plugin](https://github.com/33cn/plugin)
belong in those repositories, where they can be assessed by the code's own
maintainers.

## What is not a security issue

- A bug that cannot affect a running network: use the normal issue tracker.
- A scanner result with no described path from input to impact.

## Supported versions

Only the [latest release](https://github.com/bityuan/bityuan/releases/latest) receives
security fixes. `master` is a development branch and is never deployed.

Older releases can still connect: the network admits any peer at or above the
version floor compiled into the binary, which is deliberately behind the latest
release so that an upgrade rollout is possible. Being admitted is not the same as
being supported.
