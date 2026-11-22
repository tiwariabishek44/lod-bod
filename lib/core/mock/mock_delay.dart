/// Simulates network latency for each mock repository operation.
const mockRepositoryDelay = Duration(seconds: 2);

Future<void> waitForMockRepository() =>
    Future<void>.delayed(mockRepositoryDelay);
