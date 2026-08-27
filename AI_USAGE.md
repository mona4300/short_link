# How AI was used

This project was built with AI (Cursor). AI did not own the design.

**URL safety helpers** (`ip_address_parser.rb`, `dns_resolver.rb`, `address_policy.rb`) depend on IP and DNS knowledge. AI explained the concepts, constraints, and security risks (SSRF, private/loopback IPs, **obfuscated** addresses), then proposed several approaches. The reasonable one was chosen by a human.

**Everything else** (API, encoder, validator flow, models, Docker, tests) was also written with AI, but from a fully specified design: structure, code, and data flow were decided first; AI implemented that plan.