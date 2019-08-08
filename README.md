# F3load

A load test tool written in Elixir.

The goals for this tool are :

- [ ]  To define arbitrary test scenarios based in language agnostic protocols (http, sqs)
- [ ]  To schedule load tests, scaling the number of virtual users and iteratios, like in k6.
- [ ]  To run those load tests concurrently
- [ ]  To monitor progress of currently running load tests and to be able to pause/cancel them
- [ ]  To keep a history of past load test runs and gather basic metrics such as iteration througput and percentiles of latency
- [ ]  To export aggregated performance metrics so that it can be easily plotted
- [ ] Provide with a simple Restful API so that this tool can be easily integrated into existing CI/CD pipelines
- [ ] Provide notifications via Slack


