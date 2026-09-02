import os

/// A fact about a type, worked out the first time the type is met and kept.
///
/// Every question the policy asks of a type has the same answer for the
/// life of the process, and several of them cost microseconds or milliseconds
/// to ask, so each is asked once. Behind a lock rather than a note saying
/// "main thread only".
final class PerType<Value: Sendable> {

    private let known = OSAllocatedUnfairLock(initialState: [ObjectIdentifier: Value]())

    func value(for type: Any.Type, orCompute compute: () -> Value) -> Value {

        let key = ObjectIdentifier(type)

        if let known = known.withLock({ $0[key] }) { return known }

        let value = compute()

        known.withLock { $0[key] = value }

        return value
    }
}
