# PBD — private by default

A Cobrowse redaction example for UIKit and SwiftUI. Every screen is hidden from
the agent, and one file decides which ones are shown.

No view in this app carries a redaction modifier. Nothing in the examples knows
the policy exists.

## The rule

**Everything is hidden. `Approvals.swift` is the only thing that reveals.**

```swift
extension MakePaymentView: ApprovedForCobrowse {}
extension ExplainMyBillView: ApprovedForCobrowse {}
extension ContactUsView: ApprovedForCobrowse {}
```

A screen written next year is private the first time it is shown, with nobody
having remembered anything. Approving one is a line; forgetting to costs a black
rectangle.

The protocol is empty — the conformance *is* the statement, and it can be
written here without touching the type it approves.

That is the whole API. A tab, a popover, a pushed screen and a sheet are all
approved the same way, and nothing in the policy reads a type's name.

## Running it

Every example carries two pills, bottom right: which framework drew it, and an
eye — green where the policy approves it, red and slashed where it does not.
Both are read from `Approvals.swift`, so a screen can never claim to be approved
while the policy denies it.

Watch the session from the agent side to see what is actually sent. The device
shows everything normally either way.

## How it works

Two questions, asked of every view controller, independently.

**What is covered** — `cobrowseRedactedViews(for:)` covers the **whole
window**, for every controller the SDK asks about, *without consulting
approval*. There is no decision to get wrong, so a screen nobody thought about
is still covered, and so is anything a screen draws around its containers. An
alert presents into a window of its own, and that window is covered the same
way.

**What comes back** — `cobrowseUnredactedViews(for:)` reveals nothing but a
screen `Approvals.swift` names, and of that screen only its own view. The SDK
does the rest: a redaction that contains an unredaction is moved down onto
everything *beside* the revealed view, so one approved screen shows and the
rest of the window stays black. A screen never reveals its neighbours, its
chrome, or anything presented over it. Returning nothing leaves the blanket
standing, so silence is always safe.

The blanket has one visible cost: during a push between two approved screens,
views that belong to no controller are on screen and nothing reveals them, so
the agent sees a brief black frame. Not yet profiled.

Chrome is denied by default: a navigation title can name a screen the agent is
not meant to know about. Two commented blocks in `cobrowseUnredactedViews` turn
it back on.

## Naming a screen

The hard part is not the policy, it is working out **which screen a view
controller is showing**. `ShownView.swift` does that, and its answer is a
three-way `Verdict`: `approved`, `refused` (a screen was found and it is not
approved) or `unknown` (nothing here names a screen), each carrying its reason.
`UIViewController+Screen.swift` asks it of the right thing for each controller.

SwiftUI makes several controllers the app never asks for, and only one carries
the screen's type plainly:

```
UIHostingController<MakePaymentView>        the app hosted it — the type IS the screen
NavigationStackHostingController<AnyView>   a stack's root and each destination
PresentationHostingController<AnyView>      a sheet, cover or popover
TabHostingController                        hosts a SwiftUI-internal RootView
```

One walk, on two substrates:

1. **Ask the value.** The hosted view is a value, and a value answers
   `is ApprovedForCobrowse` directly. Approval travels through SwiftUI's
   wrappers by conditional conformance — `ModifiedContent`, `Optional`, and
   `_ConditionalContent` where **every** branch is approved — so most screens
   answer before anything is peeled. Where SwiftUI's wrapper cannot be named
   in source (`AnyView`'s box, `SheetContent`), `Mirror` steps inside it.

   Unanimity is only the conformance shortcut, not the whole rule. Where a
   choice's branches disagree, the walk **descends into the branch on
   display** — a `_ConditionalContent` value holds only the live one — so a
   choice with one approved side shows that side and hides the other. That is
   what makes one-sided approval work at all: a conformance keyed on one
   branch would read "approved" in both states, because the type is identical
   either way. The exception is a TAB, whose declaration is read off-graph; see
   Limitations.
2. **Then the body.** Where the value runs out — a `LazyView` holding a
   closure — the wrapper is SwiftUI's own, and its `body` is the view the
   closure returns, so the walk asks for it and continues on the value. A tab
   is read the same way: the container's `body` is the `TabView`, and its
   `TupleView.value` holds each tab as a value, so a tab is a type that
   conformance can be asked about. A body is evaluated once per type and
   remembered, never where `Body == Never`.
3. **Then the container.** A stack's root hosts only navigation plumbing, so it
   borrows the verdict of the nearest ancestor that has one of its own — its
   tab, or the screen owning the stack. Only the root borrows.

Two boundaries keep the walk honest, and each was a measured leak without it:
it **never enters a value the developer wrote**, and it **descends only
through a single slot**. A view holding an approved view as a stored property
is not that view; a `Text` carrying an approved destination is a `Text`.

Every route fails closed. A screen that cannot be reached stays hidden. No
runtime SPI and no type-name parsing is used: `_ConditionalContent` is
underscored but public, being what `@ViewBuilder` returns for an `if`.

Evaluating a container's `body` outside SwiftUI's graph is the one liberty
taken. It happens once per container type, only for a view that hosts a
`TabView`, and a `@State` read there returns its initial value with a SwiftUI
warning logged once. A body that does real work in a property wrapper would
do that work once.

## Limitations

Measured against SDK 3.19.2 on iOS 18.6, 26.5 and 27.0, iPhone and iPad.

- **Content an approved screen draws beside a container.** A bar added around a
  `NavigationStack` or `TabView` with `.overlay` or `.safeAreaInset` stays
  visible: SwiftUI draws it into a layer with no backing view, so there is
  nothing for the SDK to cover. Add `.cobrowseRedacted()` to that content.
  Covered by `TransmittedFrameTests`.

### These stay hidden — the screen cannot be named

- **ANY CONDITIONAL TAB — a tab that switches its content, or one that exists
  in some states and not others.** It stays hidden in every state, including
  on the approved screen. It fails closed, so nothing leaks, but the approved
  screen is hidden too.

  **Why a tab is the one container like this.** Everywhere else SwiftUI hands
  us the content as a VALUE from its render graph: a hosting controller is
  generic over it (`UIHostingController<MyView>`), a presentation holds it in
  an `AnyView`, a pushed destination is the already-resolved result of the
  closure. A `_ConditionalContent` value holds only its live branch, so in all
  those places the branch we read is the branch on screen.

  A `TabView`'s children are a variadic view **list**, and SwiftUI materialises
  list elements through the graph rather than by holding a value. A tab's
  controller hosts a `RootView` whose content is a `_ViewList_View` carrying an
  `AGSubgraphRef` and **no view at all**. So the only way to learn a tab's
  identity is to evaluate the container's `body` OURSELVES, off-graph — and
  there a `@State` read returns its INITIAL value. The declaration is frozen
  at launch, so it cannot say which branch or which tab is live now. Measured
  2026-09-02, iOS 26.5: after a toggle the tabs on screen changed and the
  declaration did not, including when read fresh from SwiftUI's own
  `PresentationHostingController`.

  ⚠ **Do not "fix" it by trusting that declaration.** It holds one branch,
  honestly, and it is the branch that was live at launch — so a position- or
  branch-derived mapping approves the wrong screen. `DeclarationStalenessTests`
  asserts the staleness; if that test ever fails, the declaration has started
  tracking state and the fix becomes possible.

  **Routes measured and rejected**, so none needs re-walking:

  | route | why not |
  |---|---|
  | the container's declaration, off-graph | frozen at launch under `@State` (live under `@ObservedObject`, and nothing outside can tell which drives it) |
  | the tab's own hosted value | `_ViewList_View` → `AGSubgraphRef`, holds no view |
  | the tab's runtime traits | live, stable ids — but share no key with the declaration |
  | the tab's label (`tabBarItem.title`) | display text, not identity: absent for image-only tabs, duplicable (two "Account" tabs would map the unapproved one onto the approved declaration — a leak), and it moves with state |
  | `UITabBarController` public API | `tabs` is empty, `tag` is 0 for every tab, `restorationIdentifier`/`accessibilityIdentifier` nil |
  | above the tab (the tab bar controller and representable host objects) | toolbar, popover and focus plumbing only |
  | the whole UIKit chain, controllers and views | never names an app type; SwiftUI's own hosting controllers are generic over `RootView` or `AnyView` |

  The one substrate left is AttributeGraph, via that `AGSubgraphRef`. That
  would put private AG reads on the frame path, which is the thing this policy
  currently gets to say it does not do.

  **Use instead: a stable tab with the sensitive screen PUSHED** — the tab is
  always the approved screen, and signing in happens on a screen pushed from
  it, which is unapproved and hidden. Proven in `StableTabPatternTests`, and it
  is also how the platform itself presents a sign-in.

- **A `TabView` whose declaration cannot be aligned with its tabs at all** —
  the same cause as above, one step wider: the count on screen is the only
  runtime signal, so where it cannot determine which tabs are present, the
  whole container is refused and every tab in it stays hidden, including the
  unconditional ones. Two mutually exclusive `if` tabs are exactly this shape.
- **A `TabView` built with the iOS 18 `Tab { }` API.** Measured: the reader
  declares **one** tab where there are two, so nothing in the container is
  identified and every tab is hidden, approved ones included. The old
  `.tabItem` API is unaffected. `Tabs.read(from:)` looks for a `TupleView` of
  tab values; `Tab { }` produces `TabView<Never, Content<_TupleTabContent<…>>>`
  whose content is a `Content`, so the tuple is never reached. The elements ARE
  reachable two levels further in, at
  `content._content.wrappedValue._identifiedView.value` — that is the fix if it
  is taken on. Both halves asserted in `NewTabApiTests`, with the old API as
  the control.
- **A wrapper from a third-party module.** The walk never enters a value the
  developer wrote, so a library's own container around an approved view is
  refused as a screen. Approve the library type itself if that is what shows.

`ConditionalApprovalDemoView` shows a one-sided conditional in the two places
it WORKS: **Pushed**, a `navigationDestination` that switches between an
approved and an unapproved screen, and **Presented**, a sheet whose content is
an `if/else` between the two. Both are judged by the branch on display. A
conditional TAB is deliberately not demonstrated, because it can only ever show
black and an example that always fails teaches nothing.

Conditional content also works at the two other shapes an app writes it in,
both asserted in `RealConditionalShapeTests`: an app root that is a conditional
(`WindowGroup { if signedIn { A() } else { B() } }`, where the hosted rootView
IS the `_ConditionalContent`) and a conditional sheet, cover or popover.

### Windows the SDK never asks about

The blanket covers the window of every controller the SDK asks about, which
includes the window an alert presents into. A window with no tracked
controller — an overlay an app creates for a toast or HUD — is not asked
about, and is not covered. Not measured.

## Debugging

Run with `-HostDump` to print the live controller tree, what each controller hosts, and what
the policy managed to name:

```
🌳 UIHostingController<TabsDemoView>   hosts: TabsDemoView  approved
🌳     UIKitTabBarController           hosts: none  names no screen: hosts no SwiftUI view
🌳         TabHostingController        hosts: RootView  approved  tab: ModifiedContent<ApprovedTabView, …>
🌳         TabHostingController        hosts: RootView  REFUSED: ModifiedContent<UnapprovedTabView, …> is not approved  tab: ModifiedContent<UnapprovedTabView, …>
```

Each line ends with the controller's own verdict and its reason. A stack's
root reads `names no screen` and borrows from the line above it.

A controller marked `⚠️ NEVER ASKED` is one the SDK does not track — no policy
can cover it. Filter the console on 🌳.

`./testrun.sh` runs the suite and reads the run's own verdict; `PBD_SIM=<udid>`
points it at another simulator, **which is worth doing on the next OS before
shipping** — a `TabView`'s controller stopped populating `viewControllers` in
iOS 27 and took every SwiftUI tab with it, silently, and only a run on 27 said
so. `PBDTests`
asserts through the policy rather than its parser, so the identification rules
survive a rewrite of how types are read; `TransmittedFrameTests` goes further
and reads pixels out of the frame the SDK would send, which is the only oracle
that has ever caught the surprises in this example.

## The other policy

`RedactedByRegexDelegate` is the contrast: it shows every screen and hides text
matching a pattern. Assign it in `AppDelegate` to compare.

It reads UIKit text only — SwiftUI does not draw through `UILabel`, which is why
UIKit twins of the payment screens exist. It is here to make the argument, not
as a recommendation: matching content is a poor substitute for knowing which
screen you are on.

## Notes

- `CobrowseIO.redactedViews` and `unredactedViews` take **class names** and must
  be set **before `start()`**. The list in `AppDelegate` names UIKit's own
  popover chrome — dimming, shadow and outline views that draw no app content.
- Only name views that can never be an **ancestor** of app content. An
  unredaction shields everything beneath it: naming a container there was
  measured to make unapproved screens visible.
