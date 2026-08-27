# Future work

## Security

- Integrate [Google Safe Browsing](https://developers.google.com/safe-browsing) to reject known-malicious URLs at encode time.
- Re-validate the stored URL on decode (Safe Browsing and existing URL checks) so a destination that was clean at encode time cannot later serve a changed or blacklisted target.
- Add rate limiting on encode and decode.
- Add user registration, login, and authentication, with a per-user encode quota.

## Functionality

Monitor short-code collision rate (unique-index retries / `CodeCollisionError`). Options:

- Database counters or tables
- Application logs shipped to Elasticsearch, New Relic, or similar

Alert when the rate crosses a threshold. An ongoing spike is a signal to increase `ShortLink::CODE_LENGTH`.

## Scaling

Scale in this order:

1. **Vertical** — raise Passenger and Nginx worker counts; size up the app and database servers.
2. **Partition** — if encode volume and table size grow large, partition `short_links`.
3. **Horizontal** — run more app containers or Kubernetes pods.
   - Decode-heavy: add read replicas.
   - Encode-heavy: consider sharding.
