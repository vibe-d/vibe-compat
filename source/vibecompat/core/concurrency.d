module vibecompat.core.concurrency;

public import vibe.core.concurrency;
import vibe.core.core : Task;
import core.time : Duration;

/// Forwards to `std.concurrency.send`.
void sendCompat(ARGS...)(Task task, ARGS args)
@trusted {
	assert (task != Task(), "Invalid task handle");
	static assert(args.length > 0, "Need to send at least one value.");
	foreach (A; ARGS)
		static assert(isWeaklyIsolated!A, "Only objects with no unshared or unisolated aliasing may be sent, not "~A.stringof~".");
	send(task.tid, args);
}

/// Forwards to `std.concurrency.prioritySend`.
void prioritySendCompat(ARGS...)(Task task, ARGS args)
@trusted {
	assert (task != Task(), "Invalid task handle");
	static assert(args.length > 0, "Need to send at least one value.");
	foreach (A; ARGS)
		static assert(isWeaklyIsolated!A, "Only objects with no unshared or unisolated aliasing may be sent, not "~A.stringof~".");
	prioritySend(task.tid, args);
}

/// Forwards to `std.concurrency.receive`.
void receiveCompat(OPS...)(OPS ops)
@trusted {
	receive(ops);
}

/// Forwards to `std.concurrency.receiveOnly`.
auto receiveOnlyCompat(ARGS...)()
@trusted {
	foreach (A; ARGS)
		static assert(isWeaklyIsolated!A, "Only objects with no unshared or unisolated aliasing may be sent, not "~A.stringof~".");
	return receiveOnly!ARGS();
}

/// Forwards to `std.concurrency.receiveTimeout`.
bool receiveTimeoutCompat(OPS...)(Duration timeout, OPS ops)
@trusted {
	return receiveTimeout(timeout, ops);
}

/// Forwards to `std.concurrency.setMaxMailboxSize`.
void setMaxMailboxSizeCompat(Task task, size_t messages, OnCrowding on_crowding)
@trusted {
	setMaxMailboxSize(task.tid, messages, on_crowding);
}


@safe unittest {
	import vibe.core.core : exitEventLoop, runEventLoop, runTask, sleep;
	import core.time : seconds;

	auto t = runTask({
		assert(receiveOnlyCompat!int == 42);
		receiveCompat((string s) {
			assert(s == "foo");
		});
		receiveTimeoutCompat(10.seconds, (int i) {
			assert(i == 43);
		});
	});
	t.setMaxMailboxSizeCompat(10, OnCrowding.block);
	t.sendCompat(42);
	sleep(1.seconds);
	t.sendCompat(43);
	t.prioritySendCompat("foo");
	t.join();
}
