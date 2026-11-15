# Pigeon Simulator – Brașov (proiect Godot 4)

Un porumbel în centrul vechi din Brașov, fugărit de copii cu praștii, pistoale cu apă și plase.
Harta e făcută din datele reale OpenStreetMap: străzile, Piața Sfatului, Casa Sfatului, Biserica Neagră
și cele 418 clădiri sunt la poziția și înălțimea lor reală, dar cu aspect de joc.

## Cum îl deschizi

1. Descarcă **Godot 4.7** (versiunea standard, nu .NET) de pe godotengine.org.
2. Dezarhivează folderul acesta.
3. Deschide Godot, apasă **Import** și alege fișierul `project.godot` din folder.
   Prima deschidere durează puțin, pentru că Godot importă harta (`assets/world.glb`).
4. Apasă **F5** (sau butonul Play din dreapta sus) ca să joci.

## Cele 3 porumbei

Porumbelul evoluează după câte sticle ai strâns în total (sticlele cheltuite în chioșc contează și ele):

| Nivel | Nume | Sticle strânse |
|---|---|---|
| 1 | Pigeon Basic | de la început |
| 2 | Pigeon Semi-Evoluat | 15 |
| 3 | Pigeon Evoluat | 40 |

La fiecare nivel devine mai mare, mai rapid și sare mai sus. Numele, pragurile și mărimile le schimbi din Inspector: selectezi nodul **Game** din `scenes/main.tscn`, grupul „Porumbelul”.
Modelele sunt `assets/pigeon_0.glb`, `pigeon_1.glb` și `pigeon_2.glb`.

## Controale

| Tastă | Ce face |
|---|---|
| W A S D | mers |
| Space | săritură; a doua săritură în aer aruncă ouă și îi aruncă pe copii înapoi |
| Space (ținut, în cădere) | planare (după ce o cumperi) |
| Mouse | cameră (click în joc ca să prindă mouse-ul) · rotița = zoom |
| E | intri / ieși din chioșcul de Actimel |
| 1 – 7 | cumperi în chioșc |
| Esc | pauză |

## Cum editezi jocul în editor (fără cod)

Deschide `scenes/main.tscn` (dublu-click în FileSystem). În panoul **Scene** (stânga sus) ai:

| Nod | Ce e | Ce poți face |
|---|---|---|
| **Game** | regulile jocului | selectează-l și, în **Inspector** (dreapta), schimbi vieți, copii, sticle, prețuri, evoluții |
| **Mediu** | cerul, ceața, lumina ambientală | Inspector → Environment |
| **Soare** | lumina soarelui și umbrele | îl rotești (tasta E) ca să schimbi ora zilei; Energy = cât de puternic e |
| **Oras** | toată harta Brașovului | o vezi în fereastra 3D |
| **Chiosc** | chioșcul de Actimel | îl muți cu tasta **W** (săgețile) oriunde pe hartă |
| **Porumbel** | locul de start | îl muți ca să schimbi de unde pornești; în Inspector ai viteză, săritură, gravitație, distanța camerei |

Pentru a te mișca în fereastra 3D: ține **click dreapta** și folosește **W A S D** (ca într-un joc), rotița = zoom.
Unelte: **Q** selectare, **W** mutare, **E** rotire, **R** mărire. Apoi **Ctrl+S** și **F5**.

### Toate setările din nodul Game (Inspector)

| Grup | Ce găsești |
|---|---|
| Porumbelul | vieți, cât timp ești invincibil după o lovitură, cât de tare te împinge lovitura |
| Evoluții | numele celor 3 porumbei, câte sticle trebuie, mărimea, bonusul de viteză și săritură |
| Ouă (a doua săritură) | pauza dintre explozii, raza, numărul de ouă, cât de tare zboară copiii, cât rămân ouăle pe jos |
| Copiii | câți, cât de repede apar, viteza, cât plutesc, cât stau amețiți, la ce distanță apar / dispar |
| Copii cu praștie / pistol cu apă / plasă | raza de atac, pauza dintre atacuri, viteza proiectilelor |
| Sticle | câte, mărimea, șansa să fie pe acoperiș, cât durează să reapară, cât de des apar cele aurii |
| Puteri aurii | numele, durata și puterea fiecăreia (scut, uriaș, turbo, ploaie de ouă) |
| Chioșc | numele și prețurile produselor, bonusurile pe nivel, bătăile de aripi, raza magnetului |
| Interfață | textele din meniu, pauză și „prins”, culorile, ce bare se văd pe ecran |

Pe nodul **Porumbel** ai și grupurile „Mișcare” (viteză, săritură, gravitație, accelerație, planare, bătaie de aripi, cât de abrupt poate fi un acoperiș) și „Cameră” (sensibilitatea mouse-ului, zoom minim/maxim).

Dacă strici ceva, click pe săgeata rotundă de lângă o valoare din Inspector o readuce la valoarea inițială.

Exemple:
- Selectezi **Game** → în Inspector, la „Porumbelul”, pui `Sticle Pentru Semi` = 3 → F5 → evoluezi după 3 sticle.
- Selectezi **Chiosc** → îl tragi lângă Biserica Neagră → F5 → chioșcul e acolo.
- Selectezi **Soare** → în Inspector schimbi `Light Color` în portocaliu → apus de soare.

Copiii, sticlele și ouăle apar din cod când pornește jocul, de aceea nu se văd în editor.

## Ce poți schimba în cod

Totul e în fișierul `scripts/game.gd`, sus de tot, la secțiunea **setări** (aceleași valori ca în Inspector).

## Structura

```
assets/   world.glb (harta), pigeon_0/1/2.glb (cele 3 evoluții), kid_*.glb (9 copii), bottle*.glb
data/     world_data.json – grila de străzi pentru copii, locul chioșcului, locurile sticlelor
scripts/  game.gd (regulile), player.gd (porumbelul), kid.gd (copiii), hud.gd (interfața)
scenes/   main.tscn
ui/       iconițe și fonturile Bangers + Nunito (licență OFL, în ui/fonts)
tests/    teste automate (nu sunt necesare pentru joc)
```

## Publicare pe itch.io

1. În Godot: **Editor → Manage Export Templates → Download and Install** (o singură dată).
2. **Project → Export…** – presetul **Web (itch.io)** e deja făcut. Apasă **Export Project**
   și alege un folder gol (ex. `build/web`), cu numele fișierului `index.html`.
3. Fă un **.zip** cu tot ce e în folderul acela (fișierele direct în zip, nu într-un subfolder).
4. Pe itch.io: **Create new project → Kind of project: HTML → Upload files** (zip-ul),
   bifează **This file will be played in the browser**, setează dimensiunea la 1280 × 720 și salvează.

Exportul e făcut fără „thread support”, așa că nu trebuie bifată opțiunea SharedArrayBuffer pe itch.io.

## Date hartă

Harta folosește date © OpenStreetMap contributors (licență ODbL).
Pune textul acesta în descrierea jocului de pe itch.io.
