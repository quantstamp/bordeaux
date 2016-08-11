/**
	This model is completed sliped into the constriants to find out the properites of each constraint.
*/

open util/ordering [State] as so
open util/ordering [Mutex] as mo

sig Process {}
sig Mutex {}

sig State { holds, waits: Process -> Mutex }


pred Initial [s: State]  { no s.holds + s.waits }

pred IsFree [s: State, m: Mutex] {
   // no process holds this mutex
   no m.~(s.holds)
   // all p: Process | m !in p.(this.holds)
}

pred IsStalled [s: State, p: Process] { some p.(s.waits) }

pred GrabMutex [s: State, p: Process, m: Mutex, s': State] {
   // a process can only act if it is not
   // waiting for a mutex
   !s.IsStalled[p]
   // can only grab a mutex we do not yet hold
   m !in p.(s.holds)
   s.IsFree[m] => {
      // if the mutex is free, we now hold it,
      // and do not become stalled
      p.(s'.holds) = p.(s.holds) + m
      no p.(s'.waits)
   } else {
    // if the mutex was not free,
    // we still hold the same mutexes we held,
    // and are now waiting on the mutex
    // that we tried to grab.
    p.(s'.holds) = p.(s.holds)
    p.(s'.waits) = m
  }
  all otherProc: Process - p | {
     otherProc.(s'.holds) = otherProc.(s.holds)
     otherProc.(s'.waits) = otherProc.(s.waits)
  }
}

pred ReleaseMutex [s: State, p: Process, m: Mutex, s': State] {
   !s.IsStalled[p]
   m in p.(s.holds)
   p.(s'.holds) = p.(s.holds) - m
   no p.(s'.waits)
   no m.~(s.waits) => {
      no m.~(s'.holds)
      no m.~(s'.waits)
   } else {
      some lucky: m.~(s.waits) | {
        m.~(s'.waits) = m.~(s.waits) - lucky
        m.~(s'.holds) = lucky
      }
   }
  all mu: Mutex - m {
    mu.~(s'.waits) = mu.~(s.waits)
    mu.~(s'.holds)= mu.~(s.holds)
  }
}

// for every adjacent (pre,post) pair of States,
// one action happens: either some process grabs a mutex,
// or some process releases a mutex,
// or nothing happens (have to allow this to show deadlocks)
pred GrabOrRelease  {
    Initial[so/first] &&
    (
    all pre: State - so/last  | let post = so/next [pre] |
       (post.holds = pre.holds && post.waits = pre.waits)
        ||
       (some p: Process, m: Mutex | pre.GrabMutex [p, m, post])
        ||
       (some p: Process, m: Mutex | pre.ReleaseMutex [p, m, post])

    )
}

pred Deadlock  {
         some Process
         some s: State | all p: Process | some p.(s.waits)
}

pred GrabbedInOrder  {
   all pre: State - so/last |
     let post = so/next[pre] |
        let had = Process.(pre.holds), have = Process.(post.holds) |
        let grabbed = have - had |
           some grabbed => grabbed in mo/nexts[had]
}

assert /*DijkstraPreventsDeadlocks*/assert1 {
   some Process && GrabOrRelease && GrabbedInOrder => ! Deadlock
}


pred ShowDijkstra  {
    GrabOrRelease && Deadlock
    some waits
}
pred U{! Deadlock }

pred A {some Process}

pred B {GrabOrRelease}
pred C {GrabbedInOrder}

pred AB {A and B}

pred BC {B and C and some holds}

pred AC {A and C}

pred ABC {A and B and C}

run U for 5 State, 5 Process, 4 Mutex
run A for 5 State, 5 Process, 4 Mutex
run B for 5 State, 5 Process, 4 Mutex
run C for 5 State, 5 Process, 4 Mutex

run AB for 5 State, 5 Process, 4 Mutex
run BC for 5 State, 5 Process, 4 Mutex
run AC for 5 State, 5 Process, 4 Mutex

run ABC for 5 State, 5 Process, 4 Mutex

//run {some Process && GrabOrRelease && GrabbedInOrder}  for 5 State, 5 Process, 4 Mutex
//check assert1 for 5 State, 5 Process, 4 Mutex

