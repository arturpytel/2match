# J.A.R.V.I.S. — głosowy panel sterowania z Claude'em

Panel w stylu Iron Mana: animowany rdzeń, status systemu, dziennik rozmowy.
Mówisz **„Jarvis”** → Jarvis się budzi, słucha, odpowiada głosem.
Na pytania odpowiada Claude, a proste rzeczy (godzina, otwieranie stron, minutnik, pogoda) robi sam, bez internetu do AI.

## Uruchomienie

**Windows:** kliknij dwa razy `start-jarvis.bat`.
Otworzy się Microsoft Edge w trybie aplikacji (bez paska adresu, wygląda jak osobny program).
Za pierwszym razem zezwól na mikrofon i na wyskakujące okna (to dla komend „otwórz…”).

**macOS / Linux:** `./start-jarvis.sh` (potrzebny Python 3 i Chrome albo Edge).

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
- **Autostart z Windowsem:** Win+R → `shell:startup` → wklej tam skrót do `start-jarvis.bat`.
- Klucz API zapisuje się tylko w tej przeglądarce na Twoim komputerze. Nie wrzucaj panelu z kluczem na publiczny serwer.

## Ograniczenia

Panel działa w przeglądarce, więc nie może sam uruchamiać programów, zmieniać głośności ani wyłączać komputera.
Do tego potrzebny jest mały program-pomocnik na komputerze, który można dobudować jako kolejny krok.
