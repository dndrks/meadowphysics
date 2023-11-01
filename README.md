# meadowphysics: seamstress

Adapted for seamstress by [@dndrks](https://dndrks.com) from [https://github.com/alpha-cactus/meadowphysics]() and [https://github.com/monome/monome-max-package/blob/main/javascript/mp.js]().

![](images/mp.png)

## documentation

The seamstress version of meadowphysics is based off of the original module code and should have all expected features. See the original documentation for playability instructions:

- [https://monome.org/docs/modular/meadowphysics/]()  
- [https://monome.org/docs/modular/ansible/]()

### keyboard + mouse interactions

seamstress uniquely offers keyboard and mouse interactions with the main window.

When the cascading counters are shown:

- mouse left-click: set the counter start
- <kbd>TAB</kbd>: toggle between cascading counters and scale page

When the scale page is shown:

- mouse left-click: focus on variable
- mouse wheel: increment / decrement focused variable
- <kbd>UP ARROW</kbd> / <kbd>DOWN ARROW</kbd>: cycle focus through variables within selected group
- <kbd>LEFT ARROW</kbd> / <kbd>RIGHT ARROW</kbd>: increment / decrement focused variable
- <kbd>ESC</kbd>: de-focus selected variable
- <kbd>TAB</kbd>: toggle between cascading counters and scale page

### saving + loading state

Using the PSET system that seamstress provides (run `seamstress -e hello_psets` for instruction), state data is saved to and recalled from a `meadowphysics` folder in your seamstress `data` path. To see your path, execute `path.seamstress` on the command line while seamstress is running.

Following the practice of the hardware modules, scale data is global -- each PSET reads/writes scale data to/from the same `gridscales.data` file inside of the `<seamstress_path>/data/meadowphysics` folder. This allows you to root many cascading counter explorations in the same custom scales.

## credit

*seamstress* was developed and designed by [Rylee Alanza Lyman](https://ryleealanza.org/) / [@ryleelyman](https://github.com/ryleelyman/), inspired by [matron from norns](https://github.com/monome/norns/tree/main/matron/src). matron was written by [@catfact](https://github.com/catfact). norns was initiated by [@tehn](https://github.com/tehn).

The original module's C code was adapted for norns by [@alpha-cactus](https://github.com/alpha-cactus): [https://github.com/alpha-cactus/meadowphysics]()

The seamstress version of the aforementioned Lua code was adapted and extended by [@dndrks](https://github.com/dndrks) for [monome.org](https://monome.org).

Contributions welcome. Submit a pull request or e-mail [help@monome.org](mailto:help@monome.org).
