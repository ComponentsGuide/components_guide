# Opinionated vs Flexible

If something is opinionated and well-designed, then it guides the user on a clear path to success. The system should inform the user as they build.

If something is flexible, then it allows the users to do what they like. They are not blocked from achieving essential results.

SwiftUI is an example of a system that is very flexible. Modifiers can be added to *any* element. Animation can be used to enhance property changes into transitions. However, it’s not flexible to the point that it’s hard to make something that looks and acts like an app. It provides opinions: system controls that adapt to the platform, the reactive Combine library, recommended font sizes that adjust to the user’s preference with Dynamic Type, just to name a few examples.

## Too flexible

If something is *too* flexible, it’s harder to learn. There’s a lot more cognitive load. It can be hard to form a picture in the mind of how it works. There could be multiple ways of making the same thing, and it could be unclear of which one is best.

Flexibility often begets changes to allow more flexibility. A little bit of flexibility gives way to even more, and soon the system is large enough that it’s difficult to understand.

Redux is an example of something that is extremely flexible. The functional style of the reducers allured to simplicity, but the rest of the system leaves a lot of questions unanswered. “Do I put this sort of code in the action or the connected component? Do I pass this state when the action is dispatched, or do I read from the store in my action? What sort of state do I store in a reducer: transient local, remote cache, local state to be sent to the remote?”

## Too opinionated

Opinionated without explanation produces confusion and frustration.

Too opinionated leads to an awkward or limited solution being provided when there’s an obvious, better suited approach just out of reach.

Too opinionated means *hacks* are needed to get the system to work as desired. Hacks often lead to bugs, or make things hard to change in the future.

Poorly opinionated mean that the language of the system doesn’t work well with the language of the constructors.

## Flexible enough

Enough flexibility should allow the user to achieve what they want without being overwhelmed. They shouldn’t need to resort to hacks to get something working.

Progressive disclosure can allow a system to provide a small surface area to get started with successfully, and then has extra discoverable aspects that allow more nuanced and specific behaviour.

## Opinionated enough

Enough opinions should be provided so that the team of constructors￼ is able to be aligned with the manufacturers. What they make should be consistent. They should be lead into the pit of success.

Two people given the same problem using your system should ideally come up with similar solutions. If their solutions are completely different, then there’s a communication or flexibility or other problem with your system. A solid start to an idea should be gleamed when reading the documentation for your system.

Hard common problems should either be answered with a clear and convincing solution, or explicitly be highlighted as being left to the team to come up with their own solution (likely using a flexible system).
