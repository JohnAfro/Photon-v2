# Photon 2
 Photon 2 for Garry's Mod

## Background
It's simple:

**Photon**: Major overall design flaws and extremely convoluted code that took years to get mostly stable. It also isn't able to simulate the Roto-Ray.

**Photon EX**: Good testing and research, but stability problems that are no longer worth the effort.

**Photon S**: Remains on the cutting-edge and has lots of promise, but S&box is likely still years from a release. Garry also makes breaking API changes on a regular basis and I'll never forgive the jackass for nuking the Facepunch forum.

--

**Conclusion**: Photon v2

# Major Changes

## Object Orientation
Photon 2 makes heavy use of metatables and custom inheritance to mimic traditional OOP designs. This makes it far more flexible for Photon asset creators and substantially streamlines operations overall.

## Annotations
Photon 2 is now documented using EmmyLua annotations. This provides intellisense, code validation (i.e. Lint), and static typing. 

When using VSCode, use Sumneko's Lua package to enable the annotation functionality. While it unfortunately cannot be used with any GLua plugins, I have generated annotation files scraped from the Garry's Mod Wiki (https://github.com/NullEnt1ty/gmod-wiki-scraper) as a stop-gap measure.

## Component Input Channels
Photon 2 adopts the new system of Component behavior used in Photon S (the S&box version). This dramatically streamlines advanced component behavior, like lightbars that have a special braking pattern, or flash patterns that change based on the current siren tone. 

## Compatibility

## Annotations
Annotations offer intellisense

## Structure
All core addon functions and properties should be made under the global `Photon2` table.

Sub-tables of the `Photon2` table should be made for major code sub-components when appropriate. Major sub-components should use an `sv_` or `cl_` prefix to enhance clarity on what domain something should be running in. For example, using `Photon2.cl_Network = {}` in `cl_net.lua` and `Photon2.sv_Network = {}` for `sv_net.lua`.

### Identifier Naming Conventions
* Prefix all _string_ identifiers with `Photon2:` (hooks, timers, network strings, etc.)

## Files
### Domain
Use sv_, sh_, and cl_ to designate domains. Aside from that, dashes should be used instead of underscores. (TODO)
The only Lua file in `lua/autorun` is the shared initialization file called `photon-v2_init.lua`. This file will automatically do `AddCSLuaFile()` on all client and shared files in `lua/photon-v2`. Moving code files out of `autorun` is important to control load order (more below) and enables the creation and execution of any new Lua files without restarting the game.

To ensure code initializes in the correct order (and avoid an aborted setup), a corresponding `include()` call should be inserted manually so you can confirm it's below any dependencies.

The integrity of this should also be maintained by _never_ redundantly declaring a major table more than once (e.g. doing `Photon2 = Photon2 or {}` anywhere except in `autorun/photon-v2_init.lua`).
