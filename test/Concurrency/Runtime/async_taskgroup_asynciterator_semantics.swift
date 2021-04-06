// RUN: %target-run-simple-swift(-Xfrontend -enable-experimental-concurrency -parse-as-library) | %FileCheck %s --dump-input=always
// REQUIRES: executable_test
// REQUIRES: concurrency
// XFAIL: linux
// XFAIL: windows

struct Boom: Error {}

func boom() async throws -> Int {
  throw Boom()
}

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
func test_taskGroup_next() async {
  let sum = await withThrowingTaskGroup(of: Int.self, returning: Int.self) { group in
    for n in 1...10 {
      group.spawn {
        return n.isMultiple(of: 3) ? try await boom() : n
      }
    }

    var sum = 0
    var catches = 0
    for _ in 1...5 {
      do {
        while let r = try await group.next() {
          sum += r
        }
      } catch {
        catches += 1
      }
    }

    // CHECK: catches with group.next(): 3
    print("catches with group.next(): \(catches)")

    return sum
  }

  // CHECK: result with group.next(): 37
  print("result with group.next(): \(sum)")
}

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
func test_taskGroup_for_in() async {
  let sum = await withThrowingTaskGroup(of: Int.self, returning: Int.self) { group in
    for n in 1...10 {
      group.spawn {
        return n.isMultiple(of: 3) ? try await boom() : n
      }
    }

    var sum = 0
    var catches = 0
    for _ in 1...5 {
      do {
        for try await r in group {
          sum += r
        }
      } catch {
        catches += 1
      }
    }

    // CHECK: catches with for-in: 3
    print("catches with for-in: \(catches)")

    return sum
  }

  // CHECK: result with for-in: 37
  print("result with for-in: \(sum)")
}

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
func test_taskGroup_asyncIterator() async {
  let sum = await withThrowingTaskGroup(of: Int.self, returning: Int.self) { group in
    for n in 1...10 {
      group.spawn {
        return n.isMultiple(of: 3) ? try await boom() : n
      }
    }

    var sum = 0
    var catches = 0
    for _ in 1...5 {
      var iterator = group.makeAsyncIterator()
      do {
        while let r = try await iterator.next() {
          sum += r
        }
        if try! await iterator.next() != nil {
          fatalError("Element returned from iterator after nil")
        }
      } catch {
        catches += 1
        if try! await iterator.next() != nil {
          fatalError("Element returned from iterator after throw")
        }
      }
    }

    // CHECK: catches with for-in: 3
    print("catches with for-in: \(catches)")

    return sum
  }

  // CHECK: result with async iterator: 37
  print("result with async iterator: \(sum)")
}

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
@main struct Main {
  static func main() async {
    await test_taskGroup_next()
    await test_taskGroup_for_in()
    await test_taskGroup_asyncIterator()
  }
}