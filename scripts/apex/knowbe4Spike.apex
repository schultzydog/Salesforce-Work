// Fetches 5 enrollment records and logs the raw JSON so the field mapping can be
// written against the real payload.
//
// Requires the KnowBe4 named credential to exist first.
//
//   sf apex run --file scripts/apex/knowbe4Spike.apex --target-org EG-Sandbox

KnowBe4Client.debugFirstPage();
