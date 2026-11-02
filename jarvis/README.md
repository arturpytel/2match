# J.A.R.V.I.S. — głosowy panel sterowania z Claude'em

Panel w stylu Iron Mana: animowany rdzeń, status systemu, dziennik rozmowy.
Mówisz **„Jarvis”** → Jarvis się budzi, słucha, odpowiada głosem.
Na pytania odpowiada Claude, a proste rzeczy (godzina, otwieranie stron, minutnik, pogoda) robi sam, bez internetu do AI.

## Uruchomienie

**Windows:** kliknij dwa razy `start-jarvis.bat`.
Otworzy się Microsoft Edge w trybie aplikacji (bez paska adresu, wygląda jak osobny program).
Za pierwszym razem zezwól na mikrofon i na wyskakujące okna (to dla komend „otwórz…”).

**macOS / Linux:** `./start-jarvis.sh` (potrzebny Python 3 i Chrome albo Edge).

**Ikonka na pulpicie:** kliknij raz `utworz-skrot.bat`. Na pulpicie i w menu Start pojawi się „Jarvis” z ikonką
(skrót z menu Start można przypiąć do paska zadań: prawy przycisk → „Przypnij do paska zadań”).
Ten sam plik pyta też, czy Jarvis ma się włączać razem z Windowsem.

Potem kliknij **Aktywuj system** i w **Ustawieniach** wklej klucz API Anthropic
(założysz go na https://platform.claude.com/settings/keys; płacisz za zużycie, model Haiku jest najtańszy).

## Jak mówić

| Mówisz | Co się dzieje |
|---|---|
| „Jarvis” | budzi się, mówi „Słucham?” i czeka na polecenie |
| „Jarvis, która godzina?” | od razu wykonuje |
| „otwórz YouTube / Gmail / Spotify / allegro…” | otwiera stronę |
| „wyszukaj przepis na pierogi” | szuka w Google |
| „puść lofi na YouTube” | szuka na YouTube |
| „minutnik 5 minut” | odlicza i przypomina głosem |
| „pogoda”, „status systemu”, „pełny ekran” | jasne |
| „uruchom Discorda”, „włącz Steam”, „otwórz notatnik” | uruchamia program z menu Start *(pomocnik)* |
| „zamknij Spotify” | zamyka program *(pomocnik)* |
| „głośniej”, „ciszej”, „głośność 30”, „wycisz dźwięk” | głośność komputera *(pomocnik)* |
| „pauza”, „następna piosenka”, „poprzednia” | steruje muzyką i filmami *(pomocnik)* |
| „otwórz pobrane / pulpit / dokumenty” | otwiera folder *(pomocnik)* |
| „zablokuj komputer” | blokuje ekran *(pomocnik)* |
| „wyłącz / zrestartuj / uśpij komputer” | pyta „na pewno?”, po „tak” robi to za 30 s; „anuluj wyłączenie” przerywa *(pomocnik)* |
| „stop” | przerywa mówienie |
| „nowa rozmowa” | czyści pamięć rozmowy |
| „idź spać” | usypia, aż znów usłyszy „Jarvis” |
| wszystko inne | pytanie do Claude'a |

Po odpowiedzi Jarvis przez ~7 sekund słucha dalej, więc można dopytać bez „Jarvis”.
W ustawieniach jest też **tryb rozmowy** (bez słowa budzącego), zmiana słowa budzącego, głosu, tempa i modelu.
Zamiast mówić możesz nacisnąć **spację** albo wpisać polecenie na dole.

## Wskazówki

- Działa w **Chrome** i **Edge** (inne przeglądarki nie mają rozpoznawania mowy). Najlepsze polskie głosy ma Edge („Microsoft Marek Online (Natural)”).
- Używaj **słuchawek**, wtedy Jarvis nie słyszy sam siebie. Panel ma ochronę przed echem, ale słuchawki działają pewniej.
- Klucz API zapisuje się tylko w tej przeglądarce na Twoim komputerze. Nie wrzucaj panelu z kluczem na publiczny serwer.

## Pomocnik PC (`server.ps1`, Windows)

Uruchamia się sam razem z `start-jarvis.bat`, w tle, bez okna. Serwuje panel i wykonuje komendy oznaczone *(pomocnik)*.
W panelu w „Status systemu” widać wtedy **Pomocnik PC: online** i prawdziwe obciążenie procesora, RAM i dysku.

Bezpieczeństwo:
- działa tylko na Twoim komputerze (`localhost`), z internetu nikt się do niego nie połączy;
- każde polecenie musi mieć losowy klucz, który pomocnik nadaje panelowi przy starcie, więc inne strony w przeglądarce nie wydadzą mu poleceń;
- uruchamia tylko programy z menu Start i kilka narzędzi Windows, nigdy dowolnych komend;
- wyłączenie i restart zawsze wymagają potwierdzenia „tak”.

Po zmianie plików wystarczy znowu kliknąć `start-jarvis.bat`, a stara kopia pomocnika sama się zamknie.
Na macOS i Linuksie pomocnika nie ma: działa sam panel.
