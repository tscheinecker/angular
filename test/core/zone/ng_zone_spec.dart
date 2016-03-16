library angular2.test.core.zone.ng_zone_spec;

import "dart:async";
import "package:angular2/testing_internal.dart"
    show
        AsyncTestCompleter,
        beforeEach,
        ddescribe,
        describe,
        expect,
        iit,
        inject,
        it,
        xdescribe,
        xit,
        Log,
        browserDetection;
import "package:angular2/src/facade/async.dart"
    show PromiseCompleter, PromiseWrapper, TimerWrapper, ObservableWrapper;
import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "package:angular2/src/facade/lang.dart"
    show IS_DART, scheduleMicroTask, isPresent;
import "package:angular2/src/core/zone/ng_zone.dart" show NgZone, NgZoneError;

var needsLongerTimers = browserDetection.isSlow || browserDetection.isEdge;
var resultTimer = 1000;
var testTimeout = browserDetection.isEdge ? 1200 : 500;
// Schedules a macrotask (using a timer)
void macroTask(dynamic /* (...args: any[]) => void */ fn, [timer = 1]) {
  // adds longer timers for passing tests in IE and Edge
  TimerWrapper.setTimeout(fn, needsLongerTimers ? timer : 1);
}

Log _log;
List<dynamic> _errors;
List<dynamic> _traces;
NgZone _zone;
logOnError() {
  ObservableWrapper.subscribe(_zone.onError, (NgZoneError ngErr) {
    _errors.add(ngErr.error);
    _traces.add(ngErr.stackTrace);
  });
}

logOnUnstable() {
  ObservableWrapper.subscribe(_zone.onUnstable, _log.fn("onUnstable"));
}

logOnMicrotaskEmpty() {
  ObservableWrapper.subscribe(
      _zone.onMicrotaskEmpty, _log.fn("onMicrotaskEmpty"));
}

logOnStable() {
  ObservableWrapper.subscribe(_zone.onStable, _log.fn("onStable"));
}

runNgZoneNoLog(dynamic /* () => any */ fn) {
  var length = _log.logItems.length;
  try {
    return _zone.run(fn);
  } finally {
    // delete anything which may have gotten logged.
    _log.logItems.length = length;
  }
}

main() {
  describe("NgZone", () {
    createZone(enableLongStackTrace) {
      return new NgZone(enableLongStackTrace: enableLongStackTrace);
    }
    beforeEach(() {
      _log = new Log();
      _errors = [];
      _traces = [];
    });
    describe("long stack trace", () {
      beforeEach(() {
        _zone = createZone(true);
        logOnUnstable();
        logOnMicrotaskEmpty();
        logOnStable();
        logOnError();
      });
      commonTests();
      it(
          "should produce long stack traces",
          inject([AsyncTestCompleter], (async) {
            macroTask(() {
              PromiseCompleter<dynamic> c = PromiseWrapper.completer();
              _zone.run(() {
                TimerWrapper.setTimeout(() {
                  TimerWrapper.setTimeout(() {
                    c.resolve(null);
                    throw new BaseException("ccc");
                  }, 0);
                }, 0);
              });
              c.promise.then((_) {
                expect(_traces.length).toBe(1);
                expect(_traces[0].length).toBeGreaterThan(1);
                async.done();
              });
            });
          }),
          testTimeout);
      it(
          "should produce long stack traces (when using microtasks)",
          inject([AsyncTestCompleter], (async) {
            macroTask(() {
              PromiseCompleter<dynamic> c = PromiseWrapper.completer();
              _zone.run(() {
                scheduleMicroTask(() {
                  scheduleMicroTask(() {
                    c.resolve(null);
                    throw new BaseException("ddd");
                  });
                });
              });
              c.promise.then((_) {
                expect(_traces.length).toBe(1);
                expect(_traces[0].length).toBeGreaterThan(1);
                async.done();
              });
            });
          }),
          testTimeout);
    });
    describe("short stack trace", () {
      beforeEach(() {
        _zone = createZone(false);
        logOnUnstable();
        logOnMicrotaskEmpty();
        logOnStable();
        logOnError();
      });
      commonTests();
      it(
          "should disable long stack traces",
          inject([AsyncTestCompleter], (async) {
            macroTask(() {
              PromiseCompleter<dynamic> c = PromiseWrapper.completer();
              _zone.run(() {
                TimerWrapper.setTimeout(() {
                  TimerWrapper.setTimeout(() {
                    c.resolve(null);
                    throw new BaseException("ccc");
                  }, 0);
                }, 0);
              });
              c.promise.then((_) {
                expect(_traces.length).toBe(1);
                if (isPresent(_traces[0])) {
                  // some browsers don't have stack traces.
                  expect(_traces[0].indexOf("---")).toEqual(-1);
                }
                async.done();
              });
            });
          }),
          testTimeout);
    });
  });
}

commonTests() {
  describe("hasPendingMicrotasks", () {
    it("should be false", () {
      expect(_zone.hasPendingMicrotasks).toBe(false);
    });
    it("should be true", () {
      runNgZoneNoLog(() {
        scheduleMicroTask(() {});
      });
      expect(_zone.hasPendingMicrotasks).toBe(true);
    });
  });
  describe("hasPendingTimers", () {
    it("should be false", () {
      expect(_zone.hasPendingMacrotasks).toBe(false);
    });
    it("should be true", () {
      runNgZoneNoLog(() {
        TimerWrapper.setTimeout(() {}, 0);
      });
      expect(_zone.hasPendingMacrotasks).toBe(true);
    });
  });
  describe("hasPendingAsyncTasks", () {
    it("should be false", () {
      expect(_zone.hasPendingMicrotasks).toBe(false);
    });
    it("should be true when microtask is scheduled", () {
      runNgZoneNoLog(() {
        scheduleMicroTask(() {});
      });
      expect(_zone.hasPendingMicrotasks).toBe(true);
    });
    it("should be true when timer is scheduled", () {
      runNgZoneNoLog(() {
        TimerWrapper.setTimeout(() {}, 0);
      });
      expect(_zone.hasPendingMacrotasks).toBe(true);
    });
  });
  describe("isInInnerZone", () {
    it("should return whether the code executes in the inner zone", () {
      expect(NgZone.isInAngularZone()).toEqual(false);
      runNgZoneNoLog(() {
        expect(NgZone.isInAngularZone()).toEqual(true);
      });
    }, testTimeout);
  });
  describe("run", () {
    it(
        "should return the body return value from run",
        inject([AsyncTestCompleter], (async) {
          macroTask(() {
            expect(_zone.run(() {
              return 6;
            })).toEqual(6);
          });
          macroTask(() {
            async.done();
          });
        }),
        testTimeout);
    it(
        "should call onUnstable and onMicrotaskEmpty",
        inject([AsyncTestCompleter], (async) {
          runNgZoneNoLog(() => macroTask(_log.fn("run")));
          macroTask(() {
            expect(_log.result())
                .toEqual("onUnstable; run; onMicrotaskEmpty; onStable");
            async.done();
          });
        }),
        testTimeout);
    it(
        "should call onStable once at the end of event",
        inject([AsyncTestCompleter], (async) {
          // The test is set up in a way that causes the zone loop to run onMicrotaskEmpty twice

          // then verified that onStable is only called once at the end
          runNgZoneNoLog(() => macroTask(_log.fn("run")));
          var times = 0;
          ObservableWrapper.subscribe(_zone.onMicrotaskEmpty, (_) {
            times++;
            _log.add('''onMicrotaskEmpty ${ times}''');
            if (times < 2) {
              // Scheduling a microtask causes a second digest
              runNgZoneNoLog(() {
                scheduleMicroTask(() {});
              });
            }
          });
          macroTask(() {
            expect(_log.result()).toEqual(
                "onUnstable; run; onMicrotaskEmpty; onMicrotaskEmpty 1; " +
                    "onMicrotaskEmpty; onMicrotaskEmpty 2; onStable");
            async.done();
          }, resultTimer);
        }),
        testTimeout);
    it(
        "should call standalone onStable",
        inject([AsyncTestCompleter], (async) {
          runNgZoneNoLog(() => macroTask(_log.fn("run")));
          macroTask(() {
            expect(_log.result())
                .toEqual("onUnstable; run; onMicrotaskEmpty; onStable");
            async.done();
          }, resultTimer);
        }),
        testTimeout);
    xit(
        "should run subscriber listeners in the subscription zone (outside)",
        inject([AsyncTestCompleter], (async) {
          // Each subscriber fires a microtask outside the Angular zone. The test

          // then verifies that those microtasks do not cause additional digests.
          var turnStart = false;
          ObservableWrapper.subscribe(_zone.onUnstable, (_) {
            if (turnStart) throw "Should not call this more than once";
            _log.add("onUnstable");
            scheduleMicroTask(() {});
            turnStart = true;
          });
          var turnDone = false;
          ObservableWrapper.subscribe(_zone.onMicrotaskEmpty, (_) {
            if (turnDone) throw "Should not call this more than once";
            _log.add("onMicrotaskEmpty");
            scheduleMicroTask(() {});
            turnDone = true;
          });
          var eventDone = false;
          ObservableWrapper.subscribe(_zone.onStable, (_) {
            if (eventDone) throw "Should not call this more than once";
            _log.add("onStable");
            scheduleMicroTask(() {});
            eventDone = true;
          });
          macroTask(() {
            _zone.run(_log.fn("run"));
          });
          macroTask(() {
            expect(_log.result())
                .toEqual("onUnstable; run; onMicrotaskEmpty; onStable");
            async.done();
          }, resultTimer);
        }),
        testTimeout);
    it(
        "should run subscriber listeners in the subscription zone (inside)",
        inject([AsyncTestCompleter], (async) {
          runNgZoneNoLog(() => macroTask(_log.fn("run")));
          // the only practical use-case to run a callback inside the zone is

          // change detection after "onMicrotaskEmpty". That's the only case tested.
          var turnDone = false;
          ObservableWrapper.subscribe(_zone.onMicrotaskEmpty, (_) {
            _log.add("onMyMicrotaskEmpty");
            if (turnDone) return;
            _zone.run(() {
              scheduleMicroTask(() {});
            });
            turnDone = true;
          });
          macroTask(() {
            expect(_log.result()).toEqual(
                "onUnstable; run; onMicrotaskEmpty; onMyMicrotaskEmpty; " +
                    "onMicrotaskEmpty; onMyMicrotaskEmpty; onStable");
            async.done();
          }, resultTimer);
        }),
        testTimeout);
    it(
        "should run async tasks scheduled inside onStable outside Angular zone",
        inject([AsyncTestCompleter], (async) {
          runNgZoneNoLog(() => macroTask(_log.fn("run")));
          ObservableWrapper.subscribe(_zone.onStable, (_) {
            NgZone.assertNotInAngularZone();
            _log.add("onMyTaskDone");
          });
          macroTask(() {
            expect(_log.result()).toEqual(
                "onUnstable; run; onMicrotaskEmpty; onStable; onMyTaskDone");
            async.done();
          });
        }),
        testTimeout);
    it(
        "should call onUnstable once before a turn and onMicrotaskEmpty once after the turn",
        inject([AsyncTestCompleter], (async) {
          runNgZoneNoLog(() {
            macroTask(() {
              _log.add("run start");
              scheduleMicroTask(_log.fn("async"));
              _log.add("run end");
            });
          });
          macroTask(() {
            // The microtask (async) is executed after the macrotask (run)
            expect(_log.result()).toEqual(
                "onUnstable; run start; run end; async; onMicrotaskEmpty; onStable");
            async.done();
          }, resultTimer);
        }),
        testTimeout);
    it(
        "should not run onUnstable and onMicrotaskEmpty for nested Zone.run",
        inject([AsyncTestCompleter], (async) {
          runNgZoneNoLog(() {
            macroTask(() {
              _log.add("start run");
              _zone.run(() {
                _log.add("nested run");
                scheduleMicroTask(_log.fn("nested run microtask"));
              });
              _log.add("end run");
            });
          });
          macroTask(() {
            expect(_log.result()).toEqual(
                "onUnstable; start run; nested run; end run; nested run microtask; onMicrotaskEmpty; onStable");
            async.done();
          }, resultTimer);
        }),
        testTimeout);
    it(
        "should not run onUnstable and onMicrotaskEmpty for nested Zone.run invoked from onMicrotaskEmpty",
        inject([AsyncTestCompleter], (async) {
          runNgZoneNoLog(() => macroTask(_log.fn("start run")));
          ObservableWrapper.subscribe(_zone.onMicrotaskEmpty, (_) {
            _log.add("onMicrotaskEmpty:started");
            _zone.run(() => _log.add("nested run"));
            _log.add("onMicrotaskEmpty:finished");
          });
          macroTask(() {
            expect(_log.result()).toEqual(
                "onUnstable; start run; onMicrotaskEmpty; onMicrotaskEmpty:started; nested run; onMicrotaskEmpty:finished; onStable");
            async.done();
          }, resultTimer);
        }),
        testTimeout);
    it(
        "should call onUnstable and onMicrotaskEmpty before and after each top-level run",
        inject([AsyncTestCompleter], (async) {
          runNgZoneNoLog(() => macroTask(_log.fn("run1")));
          runNgZoneNoLog(() => macroTask(_log.fn("run2")));
          macroTask(() {
            expect(_log.result()).toEqual(
                "onUnstable; run1; onMicrotaskEmpty; onStable; onUnstable; run2; onMicrotaskEmpty; onStable");
            async.done();
          }, resultTimer);
        }),
        testTimeout);
    it(
        "should call onUnstable and onMicrotaskEmpty before and after each turn",
        inject([AsyncTestCompleter], (async) {
          PromiseCompleter<String> a;
          PromiseCompleter<String> b;
          runNgZoneNoLog(() {
            macroTask(() {
              a = PromiseWrapper.completer();
              b = PromiseWrapper.completer();
              _log.add("run start");
              a.promise.then(_log.fn("a then"));
              b.promise.then(_log.fn("b then"));
            });
          });
          runNgZoneNoLog(() {
            macroTask(() {
              a.resolve("a");
              b.resolve("b");
            });
          });
          macroTask(() {
            expect(_log.result()).toEqual(
                "onUnstable; run start; onMicrotaskEmpty; onStable; onUnstable; a then; b then; onMicrotaskEmpty; onStable");
            async.done();
          }, resultTimer);
        }),
        testTimeout);
    it(
        "should run a function outside of the angular zone",
        inject([AsyncTestCompleter], (async) {
          macroTask(() {
            _zone.runOutsideAngular(_log.fn("run"));
          });
          macroTask(() {
            expect(_log.result()).toEqual("run");
            async.done();
          });
        }),
        testTimeout);
    it(
        "should call onUnstable and onMicrotaskEmpty when an inner microtask is scheduled from outside angular",
        inject([AsyncTestCompleter], (async) {
          PromiseCompleter<dynamic> completer;
          macroTask(() {
            NgZone.assertNotInAngularZone();
            completer = PromiseWrapper.completer();
          });
          runNgZoneNoLog(() {
            macroTask(() {
              NgZone.assertInAngularZone();
              completer.promise.then(_log.fn("executedMicrotask"));
            });
          });
          macroTask(() {
            NgZone.assertNotInAngularZone();
            _log.add("scheduling a microtask");
            completer.resolve(null);
          });
          macroTask(() {
            expect(_log.result()).toEqual(
                // First VM turn => setup Promise then
                "onUnstable; onMicrotaskEmpty; onStable; " +
                    // Second VM turn (outside of angular)
                    "scheduling a microtask; onUnstable; " +
                    // Third VM Turn => execute the microtask (inside angular)

                    // No onUnstable;  because we don't own the task which started the turn.
                    "executedMicrotask; onMicrotaskEmpty; onStable");
            async.done();
          }, resultTimer);
        }),
        testTimeout);
    it(
        "should call onUnstable only before executing a microtask scheduled in onMicrotaskEmpty " +
            "and not onMicrotaskEmpty after executing the task",
        inject([AsyncTestCompleter], (async) {
          runNgZoneNoLog(() => macroTask(_log.fn("run")));
          var ran = false;
          ObservableWrapper.subscribe(_zone.onMicrotaskEmpty, (_) {
            _log.add("onMicrotaskEmpty(begin)");
            if (!ran) {
              _zone.run(() {
                scheduleMicroTask(() {
                  ran = true;
                  _log.add("executedMicrotask");
                });
              });
            }
            _log.add("onMicrotaskEmpty(end)");
          });
          macroTask(() {
            expect(_log.result()).toEqual(
                // First VM turn => 'run' macrotask
                "onUnstable; run; onMicrotaskEmpty; onMicrotaskEmpty(begin); onMicrotaskEmpty(end); " +
                    // Second microtaskDrain Turn => microtask enqueued from onMicrotaskEmpty
                    "executedMicrotask; onMicrotaskEmpty; onMicrotaskEmpty(begin); onMicrotaskEmpty(end); onStable");
            async.done();
          }, resultTimer);
        }),
        testTimeout);
    it(
        "should call onUnstable and onMicrotaskEmpty for a scheduleMicroTask in onMicrotaskEmpty triggered by " +
            "a scheduleMicroTask in run",
        inject([AsyncTestCompleter], (async) {
          runNgZoneNoLog(() {
            macroTask(() {
              _log.add("scheduleMicroTask");
              scheduleMicroTask(_log.fn("run(executeMicrotask)"));
            });
          });
          var ran = false;
          ObservableWrapper.subscribe(_zone.onMicrotaskEmpty, (_) {
            _log.add("onMicrotaskEmpty(begin)");
            if (!ran) {
              _log.add("onMicrotaskEmpty(scheduleMicroTask)");
              _zone.run(() {
                scheduleMicroTask(() {
                  ran = true;
                  _log.add("onMicrotaskEmpty(executeMicrotask)");
                });
              });
            }
            _log.add("onMicrotaskEmpty(end)");
          });
          macroTask(() {
            expect(_log.result()).toEqual(
                // First VM Turn => a macrotask + the microtask it enqueues
                "onUnstable; scheduleMicroTask; run(executeMicrotask); onMicrotaskEmpty; onMicrotaskEmpty(begin); onMicrotaskEmpty(scheduleMicroTask); onMicrotaskEmpty(end); " +
                    // Second VM Turn => the microtask enqueued from onMicrotaskEmpty
                    "onMicrotaskEmpty(executeMicrotask); onMicrotaskEmpty; onMicrotaskEmpty(begin); onMicrotaskEmpty(end); onStable");
            async.done();
          }, resultTimer);
        }),
        testTimeout);
    it(
        "should execute promises scheduled in onUnstable before promises scheduled in run",
        inject([AsyncTestCompleter], (async) {
          runNgZoneNoLog(() {
            macroTask(() {
              _log.add("run start");
              PromiseWrapper.resolve(null).then((_) {
                _log.add("promise then");
                PromiseWrapper.resolve(null).then(_log.fn("promise foo"));
                return PromiseWrapper.resolve(null);
              }).then(_log.fn("promise bar"));
              _log.add("run end");
            });
          });
          var donePromiseRan = false;
          var startPromiseRan = false;
          ObservableWrapper.subscribe(_zone.onUnstable, (_) {
            _log.add("onUnstable(begin)");
            if (!startPromiseRan) {
              _log.add("onUnstable(schedulePromise)");
              _zone.run(() {
                scheduleMicroTask(_log.fn("onUnstable(executePromise)"));
              });
              startPromiseRan = true;
            }
            _log.add("onUnstable(end)");
          });
          ObservableWrapper.subscribe(_zone.onMicrotaskEmpty, (_) {
            _log.add("onMicrotaskEmpty(begin)");
            if (!donePromiseRan) {
              _log.add("onMicrotaskEmpty(schedulePromise)");
              _zone.run(() {
                scheduleMicroTask(_log.fn("onMicrotaskEmpty(executePromise)"));
              });
              donePromiseRan = true;
            }
            _log.add("onMicrotaskEmpty(end)");
          });
          macroTask(() {
            expect(_log.result()).toEqual(
                // First VM turn: enqueue a microtask in onUnstable
                "onUnstable; onUnstable(begin); onUnstable(schedulePromise); onUnstable(end); " +
                    // First VM turn: execute the macrotask which enqueues microtasks
                    "run start; run end; " +
                    // First VM turn: execute enqueued microtasks
                    "onUnstable(executePromise); promise then; promise foo; promise bar; onMicrotaskEmpty; " +
                    // First VM turn: onTurnEnd, enqueue a microtask
                    "onMicrotaskEmpty(begin); onMicrotaskEmpty(schedulePromise); onMicrotaskEmpty(end); " +
                    // Second VM turn: execute the microtask from onTurnEnd
                    "onMicrotaskEmpty(executePromise); onMicrotaskEmpty; onMicrotaskEmpty(begin); onMicrotaskEmpty(end); onStable");
            async.done();
          }, resultTimer);
        }),
        testTimeout);
    it(
        "should call onUnstable and onMicrotaskEmpty before and after each turn, respectively",
        inject([AsyncTestCompleter], (async) {
          PromiseCompleter<dynamic> completerA;
          PromiseCompleter<dynamic> completerB;
          runNgZoneNoLog(() {
            macroTask(() {
              completerA = PromiseWrapper.completer();
              completerB = PromiseWrapper.completer();
              completerA.promise.then(_log.fn("a then"));
              completerB.promise.then(_log.fn("b then"));
              _log.add("run start");
            });
          });
          runNgZoneNoLog(() {
            macroTask(() {
              completerA.resolve(null);
            }, 10);
          });
          runNgZoneNoLog(() {
            macroTask(() {
              completerB.resolve(null);
            }, 20);
          });
          macroTask(() {
            expect(_log.result()).toEqual(
                // First VM turn
                "onUnstable; run start; onMicrotaskEmpty; onStable; " +
                    // Second VM turn
                    "onUnstable; a then; onMicrotaskEmpty; onStable; " +
                    // Third VM turn
                    "onUnstable; b then; onMicrotaskEmpty; onStable");
            async.done();
          }, resultTimer);
        }),
        testTimeout);
    it(
        "should call onUnstable and onMicrotaskEmpty before and after (respectively) all turns in a chain",
        inject([AsyncTestCompleter], (async) {
          runNgZoneNoLog(() {
            macroTask(() {
              _log.add("run start");
              scheduleMicroTask(() {
                _log.add("async1");
                scheduleMicroTask(_log.fn("async2"));
              });
              _log.add("run end");
            });
          });
          macroTask(() {
            expect(_log.result()).toEqual(
                "onUnstable; run start; run end; async1; async2; onMicrotaskEmpty; onStable");
            async.done();
          }, resultTimer);
        }),
        testTimeout);
    it(
        "should call onUnstable and onMicrotaskEmpty for promises created outside of run body",
        inject([AsyncTestCompleter], (async) {
          Future<dynamic> promise;
          runNgZoneNoLog(() {
            macroTask(() {
              _zone.runOutsideAngular(() {
                promise = PromiseWrapper
                    .resolve(4)
                    .then((x) => PromiseWrapper.resolve(x));
              });
              promise.then(_log.fn("promise then"));
              _log.add("zone run");
            });
          });
          macroTask(() {
            expect(_log.result()).toEqual(
                "onUnstable; zone run; onMicrotaskEmpty; onStable; " +
                    "onUnstable; promise then; onMicrotaskEmpty; onStable");
            async.done();
          }, resultTimer);
        }),
        testTimeout);
  });
  describe("exceptions", () {
    it(
        "should call the on error callback when it is defined",
        inject([AsyncTestCompleter], (async) {
          macroTask(() {
            var exception = new BaseException("sync");
            _zone.run(() {
              throw exception;
            });
            expect(_errors.length).toBe(1);
            expect(_errors[0]).toBe(exception);
            async.done();
          });
        }),
        testTimeout);
    it(
        "should call onError for errors from microtasks",
        inject([AsyncTestCompleter], (async) {
          var exception = new BaseException("async");
          macroTask(() {
            _zone.run(() {
              scheduleMicroTask(() {
                throw exception;
              });
            });
          });
          macroTask(() {
            expect(_errors.length).toBe(1);
            expect(_errors[0]).toEqual(exception);
            async.done();
          }, resultTimer);
        }),
        testTimeout);
  });
}
