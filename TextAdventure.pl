/* Escape_The_Bunker, by Stefan Alesi, Andreas Hasenschwandtner, Tobias Richter. */

:- dynamic i_am_at/1, at/2, holding/1, closed/1, food/1.
:- retractall(at(_, _)), retractall(i_am_at(_)), retractall(alive(_)), retractall(holding(_)), retractall(food(_)).

i_am_at(home).

path(home, e, bunkerdoor).
path(bunkerdoor, e, bunker) :- thread_create(food_timer, _, [detached(true)]).
path(bunker, e, livingroom).
path(livingroom, e, tv).
path(tv, w, livingroom).
path(livingroom, s, corridor1).
path(corridor1, n, livingroom).
path(corridor1, e, corridor2).
path(corridor2, w, corridor1).

closed(bedroomdoor).
path(corridor1, s, bedroom) :- closed(bedroomdoor), write('Die Tuer ist verschlossen. Finde einen Weg, um sie zu oeffnen.'), fail.
path(corridor1, s, bedroom) :- \+ closed(bedroomdoor).
path(bedroom, n, corridor1).

closed(schrank).
path(bedroom, w, schrank).
path(schrank, e, bedroom).

closed(vent).
path(bedroom, e, vent).
path(vent, w, bedroom).

path(corridor2, n, storage).
path(storage, s, corridor2).
path(storage, w, workbench).
path(workbench, e, storage).
path(storage, e, wardrobe).
path(wardrobe, w, storage).

at(schere, home).
at(schraubenschluessel, home).
at(dietrich, home).
at(bueroklammer, tv).
at(taschenmesser, storage).

/* These rules handle how to interact with objects */
use :- i_am_at(Place), useable_at(Place).
use :- i_am_at(Place), \+ useable_at(Place), write('Du kannst hier nichts benutzen.').

useable_at(vent) :- closed(vent), holding(schraubenschluessel), assert(holding(funkgeraet)), retract(closed(vent)), write('Du hast den Lueftungsschacht geoeffnet und ein Funkgeraet gefunden, welches jedoch keine Batterie hat.'), nl.
useable_at(vent) :- \+ closed(vent), write('Der Lüftungsschacht ist bereits offen und du hast alles genommen.'), nl.
useable_at(vent) :- \+ holding(schraubenschluessel), write('Du brauchst einen Schraubenschluessel, um den Lueftungsschacht zu oeffnen.'), nl.

useable_at(schrank) :- retract(closed(schrank)), assert(holding(batterie)), write('Du hast eine Batterie gefunden.'), nl.
useable_at(schrank) :- \+ closed(schrank), write('Du hast den Schrank bereits durchsucht.'), nl.

useable_at(corridor1) :- holding(dietrich), retract(closed(bedroomdoor)), write('Du hast die Tuer geoeffnet.'), nl.
useable_at(corridor1) :- \+ holding(dietrich), write('Du brauchst einen Schluessel, um die Tuer zu oeffnen, oder du findest einen anderen Weg :). Aber leider hast du es nicht rechtzeitig geschafft, den Schluessel mitzunehmen.'), nl.

useable_at(workbench) :- holding(bueroklammer), holding(taschenmesser), retract(holding(bueroklammer)), retract(holding(taschenmesser)), assert(holding(dietrich)), write('Du hast dir einen Dietrich gebaut. Vielleicht kannst du ihn ja einsetzen.'), nl.
useable_at(workbench) :- holding(funkgeraet), holding(batterie), retract(holding(batterie)), write('Glueckwunsch, du hast es geschafft! Du hast die Batterie in das Funkgeraet gelegt und mit dem Funkgeraet hast du das Militaer kontaktiert, und sie haben dir geholfen, aus dem Bunker zu kommen.'), nl.
useable_at(workbench) :- write('Du kannst gerade nichts craften.'), nl.

/* These rules describe how to pick up an object. */
take(X) :-
    holding(X),
    write('You''re already holding it!'),
    !, nl.

take(X) :-
    i_am_at(Place),
    at(X, Place),
    retract(at(X, Place)),
    assert(holding(X)),
    write('OK.'),
    !, nl.

take(_) :-
    write('I don''t see it here.'),
    nl.

/* These rules describe how to put down an object. */
drop(X) :-
    holding(X),
    i_am_at(Place),
    retract(holding(X)),
    assert(at(X, Place)),
    write('OK.'),
    !, nl.

drop(_) :-
    write('You aren''t holding it!'),
    nl.

/* These rules define the direction letters as calls to go/1. */
n :- go(n).
s :- go(s).
e :- go(e).
w :- go(w).

/* This rule tells how to move in a given direction. */
go(Direction) :-
    i_am_at(Here),
    path(Here, Direction, There),
    retract(i_am_at(Here)),
    assert(i_am_at(There)),
    !, look.

go(_) :-
    write('You can''t go that way.').

/* This rule tells how to look about you. */
look :-
    i_am_at(Place),
    describe(Place),
    nl,
    notice_objects_at(Place),
    nl.

/* These rules set up a loop to mention all the objects in your vicinity. */
notice_objects_at(Place) :-
    at(X, Place),
    write('There is a '), write(X), write(' here.'), nl,
    fail.

notice_objects_at(_).

/* This rule tells how to die. */
die :-
    finish.

/* Under UNIX, the "halt." command quits Prolog but does not remove the output window. On a PC, however, the window disappears before the final output can be seen. Hence this routine requests the user to perform the final "halt." */
finish :-
    nl,
    write('Game Over! Du hast nichts mehr zu essen. Bitte schreibe den command "halt." um danach noch mal zu spielen'),
    nl.

/* This rule shows what you have in your inventory */
inventory :-
    holding(X),
    write('You are holding: '), write(X), nl,
    fail.

inventory.

/* This rule just writes out game instructions. */
instructions :-
    nl,
    write('Enter commands using standard Prolog syntax.'), nl,
    write('Available commands are:'), nl,
    write('start.             -- to start the game.'), nl,
    write('n.  s.  e.  w.     -- to go in that direction.'), nl,
    write('take(Object).      -- to pick up an object.'), nl,
    write('drop(Object).      -- to put down an object.'), nl,
    write('look.              -- to look around you again.'), nl,
    write('use.               -- to use an object or open an object.'), nl,
    write('instructions.      -- to see this message again.'), nl,
    write('halt.              -- to end the game and quit.'), nl,
    write('inventory.         -- to see everything in your inventory.'), nl,
    nl.

/* This rule prints out instructions and tells where you are. */
start :-
    instructions,
    assert(food(10)),  
    look.

food_timer :-
    food(Food),
    ( Food > 0 ->
        NewFood is Food - 1,
        retract(food(Food)),
        assert(food(NewFood)),
        format('Du hast noch ~w Burger uebrig.~n', [NewFood]),
        sleep(80),  % More time until a burger is consumed
        food_timer
    ;
        die
    ).

/* These rules describe the various rooms. Depending on circumstances, a room may have more than one description. */
describe(home) :- 
    write('Du bist in deinem Haus. Du hast nicht lange Zeit, um dich zu entscheiden, welche Gegenstaende du mit in deinen Bunker nimmst, bevor eine Atombombe einschlaegt und die Oberwelt verseucht wird.'), nl, 
    write('Vor dir Richtung Osten liegt die Treppe, welche in den Bunker fuehrt.'), nl.

describe(bunkerdoor) :-
    write('Vor dir liegt eine Tuer, die in den Bunker fuehrt.'), nl.

describe(bunker) :-
    write('Du betrittst deinen Bunker. Es ist dunkel, aber du kannst dennoch die Umrisse der Objekte erkennen. Da du jetzt im Bunker bist, musst du einen Weg finden, um Hilfe von der Außenwelt anzufragen. Aber dafuer hast du nicht lange Zeit, da du nur begrenzt Essen hast.'), nl,
    write('Einige davon koennten nuetzliche Gegenstaende enthalten. Vielleicht solltest du sie durchsuchen.'), nl.

describe(livingroom) :-
    write('Du befindest dich im Wohnzimmer deines Bunkers. Hier kannst du dich ausruhen und entspannen, wenn die Welt da draußen zerstoert ist.'), nl,
    write('Es gibt einen Fernseher an der Wand und eine Tuer im Osten, die zum Korridor fuehrt.'), nl.

describe(tv) :-
    write('Der Fernseher zeigt nur statisches Rauschen. Kein Signal von draußen.'), nl.

describe(corridor1) :-
    write('Du befindest dich im Korridor deines Bunkers. Ein paar Tueren fuehren zu verschiedenen Raeumen.'), nl,
    write('Im Osten fuehrt ein Korridor weiter. Im Sueden liegt ein Schlafzimmer.'), nl.

describe(corridor2) :-
    write('Dieser Korridor ist etwas breiter als der letzte. An der Wand haengen einige Regale mit Vorraeten.'), nl,
    write('Ein Regal scheint locker zu sein. Vielleicht kannst du es untersuchen.'), nl.

describe(storage) :-
    write('Du betrittst den Lagerraum. Hier werden die lebenswichtigen Vorraete fuer den Ueberlebenskampf gelagert.'), nl,
    write('Du siehst Konserven, Wasserflaschen und Medikamente auf den Regalen.'), nl.

describe(bedroom) :-
    write('Du betrittst das Schlafzimmer. Es ist einfach, aber gemuetlich. Ein Ort zum Ausruhen und Schlafen.'), nl,
    write('Es gibt ein Bett und einen Schrank.'), nl.

describe(workbench) :-
    write('Vor dir liegt eine Werkbank vielleicht kannst du ja etwas herstellen.'), nl,
    write('Du koenntest zum Beispiel einen Dietrich bauen.'), nl.

describe(schrank) :-
    write('Vor dir befindet sich ein Schrank du koenntest ihn durchsuchen und etwas nuetzliches finden.'), nl.

describe(vent) :-
    write('Ueber dir befindet sich ein Lueftungsschacht. Du koenntest ihn wahrscheinlich mit einem Schraubenzieher oeffnen.'), nl.

/* Prepare Phase*/
