#!/usr/bin/env python3
"""Menu translations for both apps. Edit here, then run: python3 tools/menu_i18n.py
Rewrites the generated blocks in engine.swift and windows/aura.cpp (between the BEGIN/END markers).
Russian system → Ukrainian menu (no Russian translation on purpose)."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
KEYS = ["enabled", "auto", "sound", "access", "app", "exclude", "game", "appLang", "noBinding", "exclusions", "recent", "bindings", "empty", "login", "words", "save", "cancel", "uiLang", "allLangs", "regEurope", "regCaucasus", "regMiddleEast", "regAsia", "system", "hint", "report", "reportBody", "update", "updateDue", "donate", "quit", "updNew", "updLatest", "updNotes", "updNow", "updLater", "updFail", "firstRun", "caseFix", "abbrevs", "caseHint", "settings", "secGeneral", "secShortcuts", "secWords", "secApps", "secAbout", "colWord", "colApp", "colLang", "search", "add", "remove", "chooseApp", "recentApps", "version", "origRepo", "shNote", "wordsDesc", "abbrevsDesc", "excludeDesc", "bindDesc"]
# code, native name, then one line per key (in KEYS order)
LANGS = """
en English
Enabled
Auto-correction
Sound
⚠︎ Grant access: Accessibility, Input Monitoring
App:
Don't work in this app
Game — AURA paused
Language for this app
No binding
Exclusions
Don't work in (recent apps)
Language bindings
Empty
Launch at login
My words…
Save
Cancel
Menu language
All languages
Europe
Caucasus & Central Asia
Middle East
Asia
System
Double ⇧ — convert word/selection
Report a problem…
What happened and in which app:
Check for updates…
⬆︎ An update may be available — check
Support AURA Switcher ☕
Quit
AURA Switcher {v} is out
You have the latest version
What's new
Update
Later
Couldn't update automatically. Open the website to download it?
AURA Switcher is running. Its icon is in the notification area; click ^ next to the clock to open the menu
Fix letter case
Abbreviations…
⌥ + double ⇧ — change case
Settings…
General
Shortcuts
Words
Apps
About
Word
App
Language
Search
Add
Remove
Choose app…
Recent apps
Version
Original project on GitHub
These shortcuts can't be changed yet.
AURA never changes these words, and fixes them when typed in the wrong layout.
AURA writes these in capitals (TTN), even when typed in the wrong layout.
AURA does nothing in these apps. Full-screen games are paused automatically.
When you switch to one of these apps, AURA changes the layout to the chosen language.

uk Українська
Увімкнено
Автовиправлення
Звук
⚠︎ Надайте доступ: Універсальний доступ, Моніторинг введення
Програма:
Не працювати в цій програмі
Гра — AURA на паузі
Мова для цієї програми
Без прив'язки
Винятки
Не працювати в (останні програми)
Прив'язки мов
Порожньо
Запускати під час входу
Мої слова…
Зберегти
Скасувати
Мова меню
Усі мови
Європа
Кавказ і Центральна Азія
Близький Схід
Азія
Системна
Подвійний ⇧ — змінити мову слова/виділення
Повідомити про проблему…
Що сталося і в якій програмі:
Перевірити оновлення…
⬆︎ Можливо, вийшло оновлення — перевірити
Підтримати AURA Switcher ☕
Вихід
Вийшла AURA Switcher {v}
У вас остання версія
Що нового
Оновити
Пізніше
Не вдалося оновити автоматично. Відкрити сайт, щоб завантажити?
AURA Switcher працює. Значок — в області сповіщень; натисніть ^ біля годинника, щоб відкрити меню
Виправляти регістр
Абревіатури…
⌥ + подвійний ⇧ — змінити регістр
Налаштування…
Загальні
Гарячі клавіші
Слова
Програми
Про програму
Слово
Програма
Мова
Пошук
Додати
Видалити
Обрати програму…
Останні програми
Версія
Оригінальний проєкт на GitHub
Ці скорочення поки не налаштовуються.
AURA ніколи не змінює ці слова, а набрані не в тій розкладці — виправляє на них.
AURA пише їх великими літерами (ТТН), навіть якщо набрано не в тій розкладці.
У цих програмах AURA нічого не робить. Повноекранні ігри ставляться на паузу автоматично.
Коли ви перемикаєтесь на одну з цих програм, AURA змінює розкладку на обрану мову.

pl Polski
Włączone
Autokorekta
Dźwięk
⚠︎ Nadaj dostęp: Dostępność, Monitorowanie wejścia
Aplikacja:
Nie działaj w tej aplikacji
Gra — AURA wstrzymana
Język dla tej aplikacji
Bez przypisania
Wyjątki
Nie działaj w (ostatnie aplikacje)
Przypisania języków
Pusto
Uruchamiaj przy logowaniu
Moje słowa…
Zapisz
Anuluj
Język menu
Wszystkie języki
Europa
Kaukaz i Azja Środkowa
Bliski Wschód
Azja
Systemowy
Podwójny ⇧ — zmień układ słowa/zaznaczenia
Zgłoś problem…
Co się stało i w jakiej aplikacji:
Sprawdź aktualizacje…
⬆︎ Może być dostępna aktualizacja — sprawdź
Wesprzyj AURA Switcher ☕
Zakończ
Wyszła AURA Switcher {v}
Masz najnowszą wersję
Co nowego
Aktualizuj
Później
Nie udało się zaktualizować automatycznie. Otworzyć stronę, aby pobrać?
AURA Switcher działa. Ikona jest w obszarze powiadomień; kliknij ^ obok zegara, aby otworzyć menu
Popraw wielkość liter
Skróty…
⌥ + podwójny ⇧ — zmień wielkość liter
Ustawienia…
Ogólne
Skróty klawiszowe
Słowa
Aplikacje
O programie
Słowo
Aplikacja
Język
Szukaj
Dodaj
Usuń
Wybierz aplikację…
Ostatnie aplikacje
Wersja
Oryginalny projekt na GitHubie
Tych skrótów nie można jeszcze zmienić.
AURA nigdy nie zmienia tych słów, a wpisane w złym układzie poprawia na nie.
AURA zapisuje je wielkimi literami (TTN), także gdy wpisano je w złym układzie.
W tych aplikacjach AURA nic nie robi. Gry pełnoekranowe są wstrzymywane automatycznie.
Po przełączeniu na jedną z tych aplikacji AURA zmienia układ na wybrany język.

de Deutsch
Aktiviert
Autokorrektur
Ton
⚠︎ Zugriff erlauben: Bedienungshilfen, Eingabeüberwachung
App:
In dieser App nicht aktiv
Spiel — AURA pausiert
Sprache für diese App
Keine Zuordnung
Ausnahmen
Nicht aktiv in (letzte Apps)
Sprachzuordnungen
Leer
Bei Anmeldung starten
Meine Wörter…
Sichern
Abbrechen
Menüsprache
Alle Sprachen
Europa
Kaukasus und Zentralasien
Naher Osten
Asien
System
Doppel-⇧ — Wort/Auswahl umwandeln
Problem melden…
Was ist passiert und in welcher App:
Nach Updates suchen…
⬆︎ Möglicherweise gibt es ein Update — prüfen
AURA Switcher unterstützen ☕
Beenden
AURA Switcher {v} ist da
Du hast die neueste Version
Was ist neu
Aktualisieren
Später
Automatisches Update fehlgeschlagen. Website zum Herunterladen öffnen?
AURA Switcher läuft. Das Symbol ist im Infobereich; klicken Sie neben der Uhr auf ^, um das Menü zu öffnen
Groß-/Kleinschreibung korrigieren
Abkürzungen…
⌥ + Doppel-⇧ — Groß-/Kleinschreibung ändern
Einstellungen…
Allgemein
Tastenkürzel
Wörter
Apps
Info
Wort
App
Sprache
Suchen
Hinzufügen
Entfernen
App auswählen…
Zuletzt verwendete Apps
Version
Originalprojekt auf GitHub
Diese Tastenkürzel lassen sich noch nicht ändern.
AURA ändert diese Wörter nie und korrigiert im falschen Layout getippte Wörter auf sie.
AURA schreibt diese in Großbuchstaben (TTN), auch wenn sie im falschen Layout getippt wurden.
In diesen Apps tut AURA nichts. Vollbildspiele werden automatisch pausiert.
Wenn Sie zu einer dieser Apps wechseln, stellt AURA das Layout auf die gewählte Sprache um.

es Español
Activado
Autocorrección
Sonido
⚠︎ Conceder acceso: Accesibilidad, Monitorización de entrada
App:
No funcionar en esta app
Juego — AURA en pausa
Idioma para esta app
Sin asignación
Excepciones
No funcionar en (apps recientes)
Idiomas asignados
Vacío
Abrir al iniciar sesión
Mis palabras…
Guardar
Cancelar
Idioma del menú
Todos los idiomas
Europa
Cáucaso y Asia Central
Oriente Medio
Asia
Sistema
Doble ⇧ — convertir palabra/selección
Informar de un problema…
Qué pasó y en qué app:
Buscar actualizaciones…
⬆︎ Puede haber una actualización — comprobar
Apoyar AURA Switcher ☕
Salir
Ya está aquí AURA Switcher {v}
Tienes la última versión
Novedades
Actualizar
Más tarde
No se pudo actualizar automáticamente. ¿Abrir la web para descargarla?
AURA Switcher está funcionando. Su icono está en el área de notificaciones; haz clic en ^ junto al reloj para abrir el menú
Corregir mayúsculas
Abreviaturas…
⌥ + doble ⇧ — cambiar mayúsculas
Ajustes…
General
Atajos
Palabras
Apps
Acerca de
Palabra
App
Idioma
Buscar
Añadir
Quitar
Elegir app…
Apps recientes
Versión
Proyecto original en GitHub
Estos atajos aún no se pueden cambiar.
AURA nunca cambia estas palabras y corrige a ellas las tecleadas en la distribución equivocada.
AURA las escribe en mayúsculas (TTN), incluso si se teclearon en la distribución equivocada.
AURA no hace nada en estas apps. Los juegos a pantalla completa se pausan automáticamente.
Al cambiar a una de estas apps, AURA cambia la distribución al idioma elegido.

fr Français
Activé
Correction automatique
Son
⚠︎ Autoriser l'accès : Accessibilité, Surveillance de l’entrée
App :
Ne pas fonctionner dans cette app
Jeu — AURA en pause
Langue pour cette app
Aucune association
Exceptions
Ne pas fonctionner dans (apps récentes)
Langues associées
Vide
Ouvrir à la connexion
Mes mots…
Enregistrer
Annuler
Langue du menu
Toutes les langues
Europe
Caucase et Asie centrale
Moyen-Orient
Asie
Système
Double ⇧ — convertir le mot/la sélection
Signaler un problème…
Ce qui s'est passé et dans quelle app :
Rechercher des mises à jour…
⬆︎ Une mise à jour est peut-être disponible — vérifier
Soutenir AURA Switcher ☕
Quitter
AURA Switcher {v} est sortie
Vous avez la dernière version
Nouveautés
Mettre à jour
Plus tard
Mise à jour automatique impossible. Ouvrir le site pour la télécharger ?
AURA Switcher fonctionne. Son icône est dans la zone de notification ; cliquez sur ^ près de l’horloge pour ouvrir le menu
Corriger la casse
Abréviations…
⌥ + double ⇧ — changer la casse
Réglages…
Général
Raccourcis
Mots
Apps
À propos
Mot
App
Langue
Rechercher
Ajouter
Supprimer
Choisir une app…
Apps récentes
Version
Projet original sur GitHub
Ces raccourcis ne sont pas encore modifiables.
AURA ne modifie jamais ces mots et corrige vers eux ceux tapés dans la mauvaise disposition.
AURA les écrit en majuscules (TTN), même tapés dans la mauvaise disposition.
AURA ne fait rien dans ces apps. Les jeux en plein écran sont mis en pause automatiquement.
Quand vous passez à l'une de ces apps, AURA change la disposition pour la langue choisie.

it Italiano
Attivo
Correzione automatica
Suono
⚠︎ Concedi l’accesso: Accessibilità, Monitoraggio input
App:
Disattiva in questa app
Gioco — AURA in pausa
Lingua per questa app
Nessuna associazione
Esclusioni
Disattiva in (app recenti)
Lingue associate
Vuoto
Apri al login
Le mie parole…
Salva
Annulla
Lingua del menu
Tutte le lingue
Europa
Caucaso e Asia centrale
Medio Oriente
Asia
Sistema
Doppio ⇧ — converti parola o selezione
Segnala un problema…
Cosa è successo e in quale app:
Controlla aggiornamenti…
⬆︎ Potrebbe essere disponibile un aggiornamento — verifica
Sostieni AURA Switcher ☕
Esci
È disponibile AURA Switcher {v}
Hai l’ultima versione
Novità
Aggiorna
Più tardi
Impossibile aggiornare automaticamente. Vuoi aprire il sito per scaricare l’aggiornamento?
AURA Switcher è in esecuzione. L’icona è nell’area di notifica; fai clic su ^ accanto all’orologio per aprire il menu
Correggi maiuscole
Abbreviazioni…
⌥ + doppio ⇧ — cambia maiuscole
Impostazioni…
Generali
Scorciatoie
Parole
App
Info
Parola
App
Lingua
Cerca
Aggiungi
Rimuovi
Scegli app…
App recenti
Versione
Progetto originale su GitHub
Queste scorciatoie non si possono ancora modificare.
AURA non modifica mai queste parole e corregge in esse quelle digitate nel layout sbagliato.
AURA le scrive in maiuscolo (TTN), anche se digitate nel layout sbagliato.
In queste app AURA non fa nulla. I giochi a schermo intero vengono messi in pausa automaticamente.
Quando passi a una di queste app, AURA cambia il layout nella lingua scelta.

pt Português
Ativado
Correção automática
Som
⚠︎ Conceder acesso: Acessibilidade, Monitoramento de entrada
App:
Não funcionar nesta app
Jogo — AURA em pausa
Idioma para esta app
Sem associação
Exceções
Não funcionar em (apps recentes)
Idiomas associados
Vazio
Abrir ao iniciar sessão
As minhas palavras…
Guardar
Cancelar
Idioma do menu
Todos os idiomas
Europa
Cáucaso e Ásia Central
Médio Oriente
Ásia
Sistema
Duplo ⇧ — converter palavra/seleção
Comunicar um problema…
O que aconteceu e em que app:
Procurar atualizações…
⬆︎ Pode haver uma atualização — verificar
Apoiar o AURA Switcher ☕
Sair
Saiu o AURA Switcher {v}
Tem a versão mais recente
Novidades
Atualizar
Mais tarde
Não foi possível atualizar automaticamente. Abrir o site para baixar?
O AURA Switcher está a funcionar. O ícone está na área de notificação; clique em ^ junto ao relógio para abrir o menu
Corrigir maiúsculas
Abreviaturas…
⌥ + duplo ⇧ — alterar maiúsculas
Ajustes…
Geral
Atalhos
Palavras
Apps
Sobre
Palavra
App
Idioma
Pesquisar
Adicionar
Remover
Escolher app…
Apps recentes
Versão
Projeto original no GitHub
Estes atalhos ainda não podem ser alterados.
O AURA nunca altera estas palavras e corrige para elas as digitadas no layout errado.
O AURA escreve-as em maiúsculas (TTN), mesmo digitadas no layout errado.
O AURA não faz nada nestes apps. Jogos em ecrã inteiro são pausados automaticamente.
Ao mudar para um destes apps, o AURA muda o layout para o idioma escolhido.

tr Türkçe
Etkin
Otomatik düzeltme
Ses
⚠︎ Erişim izni verin: Erişilebilirlik, Girdi İzleme
Uygulama:
Bu uygulamada çalışma
Oyun — AURA duraklatıldı
Bu uygulama için dil
Atama yok
İstisnalar
Şurada çalışma (son uygulamalar)
Dil atamaları
Boş
Oturum açılışında başlat
Kelimelerim…
Kaydet
İptal
Menü dili
Tüm diller
Avrupa
Kafkasya ve Orta Asya
Orta Doğu
Asya
Sistem
Çift ⇧ — kelimeyi/seçimi dönüştür
Sorun bildir…
Ne oldu ve hangi uygulamada:
Güncellemeleri denetle…
⬆︎ Güncelleme olabilir — denetle
AURA Switcher'ı destekle ☕
Çık
AURA Switcher {v} çıktı
En son sürümü kullanıyorsunuz
Yenilikler
Güncelle
Daha sonra
Otomatik güncellenemedi. İndirmek için web sitesi açılsın mı?
AURA Switcher çalışıyor. Simgesi bildirim alanında; menüyü açmak için saatin yanındaki ^ simgesine tıklayın
Harf büyüklüğünü düzelt
Kısaltmalar…
⌥ + çift ⇧ — harf büyüklüğünü değiştir
Ayarlar…
Genel
Kısayollar
Sözcükler
Uygulamalar
Hakkında
Sözcük
Uygulama
Dil
Ara
Ekle
Kaldır
Uygulama seç…
Son uygulamalar
Sürüm
GitHub'daki özgün proje
Bu kısayollar henüz değiştirilemez.
AURA bu sözcükleri asla değiştirmez; yanlış düzende yazılanları bunlara düzeltir.
AURA bunları büyük harfle yazar (TTN), yanlış düzende yazılsalar bile.
AURA bu uygulamalarda hiçbir şey yapmaz. Tam ekran oyunlar otomatik duraklatılır.
Bu uygulamalardan birine geçtiğinizde AURA düzeni seçilen dile değiştirir.

nl Nederlands
Ingeschakeld
Autocorrectie
Geluid
⚠︎ Geef toegang: Toegankelijkheid, Invoercontrole (Input Monitoring)
App:
Niet werken in deze app
Game — AURA gepauzeerd
Taal voor deze app
Geen koppeling
Uitzonderingen
Niet werken in (recente apps)
Taalkoppelingen
Leeg
Starten bij inloggen
Mijn woorden…
Bewaar
Annuleer
Menutaal
Alle talen
Europa
Kaukasus en Centraal-Azië
Midden-Oosten
Azië
Systeem
Dubbel ⇧ — woord/selectie omzetten
Probleem melden…
Wat er gebeurde en in welke app:
Zoek naar updates…
⬆︎ Er is misschien een update — controleren
Steun AURA Switcher ☕
Stop
AURA Switcher {v} is uit
Je hebt de nieuwste versie
Wat is er nieuw
Bijwerken
Later
Automatisch bijwerken is mislukt. De website openen om te downloaden?
AURA Switcher draait. Het pictogram staat in het systeemvak; klik op ^ naast de klok om het menu te openen
Hoofdletters corrigeren
Afkortingen…
⌥ + dubbel ⇧ — hoofdletters wijzigen
Instellingen…
Algemeen
Sneltoetsen
Woorden
Apps
Over
Woord
App
Taal
Zoeken
Voeg toe
Verwijder
Kies app…
Recente apps
Versie
Oorspronkelijk project op GitHub
Deze sneltoetsen kunnen nog niet worden gewijzigd.
AURA wijzigt deze woorden nooit en corrigeert in de verkeerde indeling getypte woorden ernaar.
AURA schrijft deze in hoofdletters (TTN), ook als ze in de verkeerde indeling zijn getypt.
In deze apps doet AURA niets. Volledig-scherm-games worden automatisch gepauzeerd.
Als je naar een van deze apps overschakelt, wijzigt AURA de indeling naar de gekozen taal.

cs Čeština
Zapnuto
Automatické opravy
Zvuk
⚠︎ Udělte přístup: Zpřístupnění, Sledování vstupu
Aplikace:
Nefungovat v této aplikaci
Hra — AURA pozastavena
Jazyk pro tuto aplikaci
Bez přiřazení
Výjimky
Nefungovat v (nedávné aplikace)
Přiřazení jazyků
Prázdné
Spouštět po přihlášení
Moje slova…
Uložit
Zrušit
Jazyk nabídky
Všechny jazyky
Evropa
Kavkaz a Střední Asie
Blízký východ
Asie
Systémový
Dvojitý ⇧ — převést slovo/výběr
Nahlásit problém…
Co se stalo a v jaké aplikaci:
Zkontrolovat aktualizace…
⬆︎ Možná je k dispozici aktualizace — zkontrolovat
Podpořit AURA Switcher ☕
Ukončit
Vyšel AURA Switcher {v}
Máte nejnovější verzi
Co je nového
Aktualizovat
Později
Automatická aktualizace se nezdařila. Otevřít web a stáhnout?
AURA Switcher běží. Ikona je v oznamovací oblasti; menu otevřete kliknutím na ^ vedle hodin
Opravovat velikost písmen
Zkratky…
⌥ + dvojitý ⇧ — změnit velikost písmen
Nastavení…
Obecné
Zkratky
Slova
Aplikace
O aplikaci
Slovo
Aplikace
Jazyk
Hledat
Přidat
Odebrat
Vybrat aplikaci…
Poslední aplikace
Verze
Původní projekt na GitHubu
Tyto zkratky zatím nelze změnit.
AURA tato slova nikdy nemění a slova napsaná v nesprávném rozložení opraví na ně.
AURA je píše velkými písmeny (TTN), i když byla napsána v nesprávném rozložení.
V těchto aplikacích AURA nic nedělá. Celoobrazovkové hry se pozastaví automaticky.
Když přepnete na jednu z těchto aplikací, AURA změní rozložení na vybraný jazyk.

sv Svenska
Aktiverad
Autokorrigering
Ljud
⚠︎ Ge åtkomst: Hjälpmedel, Indataövervakning (Input Monitoring)
App:
Arbeta inte i den här appen
Spel — AURA pausad
Språk för den här appen
Ingen koppling
Undantag
Arbeta inte i (senaste appar)
Språkkopplingar
Tomt
Starta vid inloggning
Mina ord…
Spara
Avbryt
Menyspråk
Alla språk
Europa
Kaukasus och Centralasien
Mellanöstern
Asien
System
Dubbel-⇧ — konvertera ord/markering
Rapportera ett problem…
Vad hände och i vilken app:
Sök efter uppdateringar…
⬆︎ Det kan finnas en uppdatering — kontrollera
Stöd AURA Switcher ☕
Avsluta
AURA Switcher {v} är här
Du har den senaste versionen
Nyheter
Uppdatera
Senare
Kunde inte uppdatera automatiskt. Öppna webbplatsen för att ladda ner?
AURA Switcher körs. Ikonen finns i aviseringsfältet; klicka på ^ bredvid klockan för att öppna menyn
Rätta versaler/gemener
Förkortningar…
⌥ + dubbel-⇧ — ändra versaler/gemener
Inställningar…
Allmänt
Genvägar
Ord
Appar
Om
Ord
App
Språk
Sök
Lägg till
Ta bort
Välj app…
Senaste appar
Version
Originalprojektet på GitHub
De här genvägarna kan inte ändras än.
AURA ändrar aldrig dessa ord och rättar ord skrivna i fel layout till dem.
AURA skriver dessa med versaler (TTN), även om de skrivits i fel layout.
AURA gör ingenting i dessa appar. Helskärmsspel pausas automatiskt.
När du byter till någon av dessa appar byter AURA layout till det valda språket.

fi Suomi
Käytössä
Automaattinen korjaus
Ääni
⚠︎ Anna käyttöoikeus: Käyttöapu, Syötteen valvonta (Input Monitoring)
Ohjelma:
Älä toimi tässä ohjelmassa
Peli — AURA tauolla
Kieli tälle ohjelmalle
Ei liitosta
Poikkeukset
Älä toimi ohjelmassa (viimeisimmät)
Kieliliitokset
Tyhjä
Käynnistä kirjautuessa
Omat sanat…
Tallenna
Kumoa
Valikon kieli
Kaikki kielet
Eurooppa
Kaukasia ja Keski-Aasia
Lähi-itä
Aasia
Järjestelmä
Kaksois-⇧ — muunna sana/valinta
Ilmoita ongelmasta…
Mitä tapahtui ja missä ohjelmassa:
Tarkista päivitykset…
⬆︎ Päivitys saattaa olla saatavilla — tarkista
Tue AURA Switcheriä ☕
Lopeta
AURA Switcher {v} on julkaistu
Sinulla on uusin versio
Uutta
Päivitä
Myöhemmin
Automaattinen päivitys epäonnistui. Avataanko sivusto latausta varten?
AURA Switcher on käynnissä. Kuvake on ilmoitusalueella; avaa valikko napsauttamalla kellon vieressä olevaa ^-merkkiä
Korjaa kirjainkoko
Lyhenteet…
⌥ + kaksois-⇧ — vaihda kirjainkoko
Asetukset…
Yleiset
Pikanäppäimet
Sanat
Apit
Tietoja
Sana
Appi
Kieli
Hae
Lisää
Poista
Valitse appi…
Viimeisimmät apit
Versio
Alkuperäinen projekti GitHubissa
Näitä pikanäppäimiä ei voi vielä muuttaa.
AURA ei koskaan muuta näitä sanoja ja korjaa väärällä asettelulla kirjoitetut sanat niiksi.
AURA kirjoittaa nämä isoilla kirjaimilla (TTN), vaikka ne olisi kirjoitettu väärällä asettelulla.
AURA ei tee mitään näissä apeissa. Koko näytön pelit keskeytetään automaattisesti.
Kun vaihdat johonkin näistä apeista, AURA vaihtaa asettelun valittuun kieleen.

ro Română
Activat
Corectare automată
Sunet
⚠︎ Acordați acces: Accesibilitate, Monitorizare intrare (Input Monitoring)
Aplicație:
Nu funcționa în această aplicație
Joc — AURA în pauză
Limba pentru această aplicație
Fără asociere
Excepții
Nu funcționa în (aplicații recente)
Limbi asociate
Gol
Pornește la autentificare
Cuvintele mele…
Salvează
Anulează
Limba meniului
Toate limbile
Europa
Caucaz și Asia Centrală
Orientul Mijlociu
Asia
Sistem
Dublu ⇧ — convertește cuvântul/selecția
Raportează o problemă…
Ce s-a întâmplat și în ce aplicație:
Caută actualizări…
⬆︎ Poate există o actualizare — verifică
Susține AURA Switcher ☕
Ieșire
A apărut AURA Switcher {v}
Ai cea mai nouă versiune
Ce e nou
Actualizează
Mai târziu
Actualizarea automată a eșuat. Deschizi site-ul pentru descărcare?
AURA Switcher rulează. Pictograma este în zona de notificare; faceți clic pe ^ de lângă ceas pentru a deschide meniul
Corectează majusculele
Abrevieri…
⌥ + dublu ⇧ — schimbă majusculele
Setări…
General
Comenzi rapide
Cuvinte
Aplicații
Despre
Cuvânt
Aplicație
Limbă
Caută
Adaugă
Elimină
Alege aplicația…
Aplicații recente
Versiune
Proiectul original pe GitHub
Aceste comenzi rapide nu pot fi încă modificate.
AURA nu modifică niciodată aceste cuvinte și corectează în ele cuvintele tastate în aranjamentul greșit.
AURA le scrie cu majuscule (TTN), chiar dacă au fost tastate în aranjamentul greșit.
AURA nu face nimic în aceste aplicații. Jocurile pe tot ecranul sunt puse automat în pauză.
Când treci la una dintre aceste aplicații, AURA schimbă aranjamentul în limba aleasă.

hu Magyar
Bekapcsolva
Automatikus javítás
Hang
⚠︎ Hozzáférés megadása: Kisegítő lehetőségek, Bevitelfigyelés (Input Monitoring)
Alkalmazás:
Ne működjön ebben az alkalmazásban
Játék — AURA szüneteltetve
Nyelv ehhez az alkalmazáshoz
Nincs hozzárendelés
Kivételek
Ne működjön itt (legutóbbi alkalmazások)
Nyelvi hozzárendelések
Üres
Indítás bejelentkezéskor
Saját szavak…
Mentés
Mégse
Menü nyelve
Minden nyelv
Európa
Kaukázus és Közép-Ázsia
Közel-Kelet
Ázsia
Rendszer
Dupla ⇧ — szó/kijelölés átalakítása
Probléma bejelentése…
Mi történt és melyik alkalmazásban:
Frissítések keresése…
⬆︎ Lehet, hogy van frissítés — ellenőrzés
Az AURA Switcher támogatása ☕
Kilépés
Megjelent az AURA Switcher {v}
A legújabb verzió van nálad
Újdonságok
Frissítés
Később
Az automatikus frissítés nem sikerült. Megnyitod a weboldalt a letöltéshez?
Az AURA Switcher fut. Az ikonja az értesítési területen van; a menü megnyitásához kattintson az óra melletti ^ jelre
Kis- és nagybetűk javítása
Rövidítések…
⌥ + dupla ⇧ — kis-/nagybetű váltása
Beállítások…
Általános
Billentyűparancsok
Szavak
Alkalmazások
Névjegy
Szó
Alkalmazás
Nyelv
Keresés
Hozzáadás
Eltávolítás
Alkalmazás kiválasztása…
Legutóbbi alkalmazások
Verzió
Az eredeti projekt a GitHubon
Ezek a billentyűparancsok még nem módosíthatók.
Az AURA soha nem módosítja ezeket a szavakat, a rossz kiosztásban gépelteket pedig ezekre javítja.
Az AURA nagybetűvel írja őket (TTN), akkor is, ha rossz kiosztásban gépelték.
Ezekben az alkalmazásokban az AURA nem csinál semmit. A teljes képernyős játékokat automatikusan szünetelteti.
Ha ezek valamelyikére váltasz, az AURA a kiválasztott nyelvre váltja a kiosztást.

el Ελληνικά
Ενεργό
Αυτόματη διόρθωση
Ήχος
⚠︎ Δώστε πρόσβαση: Προσβασιμότητα, Παρακολούθηση εισόδου (Input Monitoring)
Εφαρμογή:
Να μη λειτουργεί σε αυτή την εφαρμογή
Παιχνίδι — AURA σε παύση
Γλώσσα για αυτή την εφαρμογή
Χωρίς αντιστοίχιση
Εξαιρέσεις
Να μη λειτουργεί σε (πρόσφατες εφαρμογές)
Αντιστοιχίσεις γλωσσών
Κενό
Εκκίνηση κατά τη σύνδεση
Οι λέξεις μου…
Αποθήκευση
Ακύρωση
Γλώσσα μενού
Όλες οι γλώσσες
Ευρώπη
Καύκασος και Κεντρική Ασία
Μέση Ανατολή
Ασία
Συστήματος
Διπλό ⇧ — μετατροπή λέξης/επιλογής
Αναφορά προβλήματος…
Τι συνέβη και σε ποια εφαρμογή:
Έλεγχος για ενημερώσεις…
⬆︎ Ίσως υπάρχει ενημέρωση — έλεγχος
Υποστηρίξτε το AURA Switcher ☕
Έξοδος
Κυκλοφόρησε το AURA Switcher {v}
Έχετε την τελευταία έκδοση
Τι νέο υπάρχει
Ενημέρωση
Αργότερα
Η αυτόματη ενημέρωση απέτυχε. Άνοιγμα του ιστότοπου για λήψη;
Το AURA Switcher εκτελείται. Το εικονίδιο βρίσκεται στην περιοχή ειδοποιήσεων· κάντε κλικ στο ^ δίπλα στο ρολόι για να ανοίξετε το μενού
Διόρθωση πεζών/κεφαλαίων
Συντομογραφίες…
⌥ + διπλό ⇧ — αλλαγή πεζών/κεφαλαίων
Ρυθμίσεις…
Γενικά
Συντομεύσεις
Λέξεις
Εφαρμογές
Σχετικά
Λέξη
Εφαρμογή
Γλώσσα
Αναζήτηση
Προσθήκη
Αφαίρεση
Επιλογή εφαρμογής…
Πρόσφατες εφαρμογές
Έκδοση
Αρχικό έργο στο GitHub
Αυτές οι συντομεύσεις δεν αλλάζουν ακόμη.
Το AURA δεν αλλάζει ποτέ αυτές τις λέξεις και διορθώνει σε αυτές όσες πληκτρολογήθηκαν σε λάθος διάταξη.
Το AURA τις γράφει με κεφαλαία (TTN), ακόμη και αν πληκτρολογήθηκαν σε λάθος διάταξη.
Σε αυτές τις εφαρμογές το AURA δεν κάνει τίποτα. Τα παιχνίδια πλήρους οθόνης σταματούν αυτόματα.
Όταν μεταβείτε σε μία από αυτές τις εφαρμογές, το AURA αλλάζει τη διάταξη στη γλώσσα που επιλέξατε.

bg Български
Включено
Автокорекция
Звук
⚠︎ Дайте достъп: Достъпност, Input Monitoring
Програма:
Да не работи в тази програма
Игра — AURA е на пауза
Език за тази програма
Без обвързване
Изключения
Да не работи в (последни програми)
Обвързани езици
Празно
Стартиране при вход
Моите думи…
Запази
Отказ
Език на менюто
Всички езици
Европа
Кавказ и Централна Азия
Близкия изток
Азия
Системен
Двоен ⇧ — смяна на езика на дума/селекция
Съобщете за проблем…
Какво се случи и в коя програма:
Проверка за актуализации…
⬆︎ Може да има актуализация — проверете
Подкрепете AURA Switcher ☕
Изход
Излезе AURA Switcher {v}
Имате най-новата версия
Какво ново
Обнови
По-късно
Автоматичното обновяване не успя. Да се отвори ли сайтът за изтегляне?
AURA Switcher работи. Иконата е в областта за известия; щракнете върху ^ до часовника, за да отворите менюто
Поправяне на главни/малки букви
Съкращения…
⌥ + двоен ⇧ — смяна на главни/малки букви
Настройки…
Общи
Клавишни комбинации
Думи
Приложения
Относно
Дума
Приложение
Език
Търсене
Добави
Премахни
Избор на приложение…
Скорошни приложения
Версия
Оригиналният проект в GitHub
Тези комбинации още не могат да се променят.
AURA никога не променя тези думи, а написаните в грешна подредба поправя на тях.
AURA ги пише с главни букви (ТТН), дори да са написани в грешна подредба.
В тези приложения AURA не прави нищо. Игрите на цял екран се паузират автоматично.
Когато превключите към някое от тези приложения, AURA сменя подредбата на избрания език.

he עברית
מופעל
תיקון אוטומטי
צליל
⚠︎ תנו גישה: נגישות, ניטור קלט (Input Monitoring)
יישום:
לא לפעול ביישום זה
משחק — AURA מושהית
שפה ליישום זה
ללא שיוך
חריגים
לא לפעול ב (יישומים אחרונים)
שיוכי שפה
ריק
הפעלה בעת התחברות
המילים שלי…
שמירה
ביטול
שפת התפריט
כל השפות
אירופה
הקווקז ומרכז אסיה
המזרח התיכון
אסיה
מערכת
⇧ כפול — המרת מילה/בחירה
דיווח על בעיה…
מה קרה ובאיזה יישום:
בדיקת עדכונים…
⬆︎ ייתכן שיש עדכון — בדיקה
תמכו ב-AURA Switcher ☕
יציאה
יצאה AURA Switcher {v}
יש לכם את הגרסה העדכנית
מה חדש
עדכן
מאוחר יותר
העדכון האוטומטי נכשל. לפתוח את האתר להורדה?
AURA Switcher פועל. הסמל נמצא באזור ההתראות; לחצו על ^ ליד השעון כדי לפתוח את התפריט
תיקון אותיות גדולות/קטנות
ראשי תיבות…
⌥ + ⇧ כפול — שינוי אותיות גדולות/קטנות
הגדרות…
כללי
קיצורי מקשים
מילים
אפליקציות
אודות
מילה
אפליקציה
שפה
חיפוש
הוספה
הסרה
בחירת אפליקציה…
אפליקציות אחרונות
גרסה
הפרויקט המקורי ב-GitHub
עדיין אי אפשר לשנות את הקיצורים האלה.
AURA לעולם לא משנה מילים אלה, ומתקנת אליהן מילים שהוקלדו בפריסה הלא נכונה.
AURA כותבת אותן באותיות גדולות (TTN), גם אם הוקלדו בפריסה הלא נכונה.
באפליקציות אלה AURA לא עושה דבר. משחקי מסך מלא מושהים אוטומטית.
כשעוברים לאחת האפליקציות האלה, AURA מחליפה את הפריסה לשפה שנבחרה.

ar العربية
مفعّل
التصحيح التلقائي
الصوت
⚠︎ امنح الوصول: تسهيلات الاستخدام، مراقبة الإدخال (Input Monitoring)
التطبيق:
لا تعمل في هذا التطبيق
لعبة — AURA متوقف مؤقتًا
لغة هذا التطبيق
بدون ربط
الاستثناءات
لا تعمل في (التطبيقات الأخيرة)
ربط اللغات
فارغ
التشغيل عند تسجيل الدخول
كلماتي…
حفظ
إلغاء
لغة القائمة
كل اللغات
أوروبا
القوقاز وآسيا الوسطى
الشرق الأوسط
آسيا
النظام
⇧ مزدوج — تحويل الكلمة/التحديد
الإبلاغ عن مشكلة…
ماذا حدث وفي أي تطبيق:
التحقق من التحديثات…
⬆︎ قد يتوفر تحديث — تحقّق
ادعم AURA Switcher ☕
إنهاء
صدر AURA Switcher {v}
لديك أحدث إصدار
ما الجديد
تحديث
لاحقًا
تعذّر التحديث تلقائيًا. هل تريد فتح الموقع للتنزيل؟
AURA Switcher يعمل. الأيقونة في منطقة الإشعارات؛ انقر على ^ بجانب الساعة لفتح القائمة
تصحيح حالة الأحرف
الاختصارات…
⌥ + ⇧ مزدوج — تغيير حالة الأحرف
الإعدادات…
عام
الاختصارات
الكلمات
التطبيقات
حول
الكلمة
التطبيق
اللغة
بحث
إضافة
إزالة
اختيار تطبيق…
التطبيقات الأخيرة
الإصدار
المشروع الأصلي على GitHub
لا يمكن تغيير هذه الاختصارات بعد.
لا يغيّر AURA هذه الكلمات أبدًا، ويصحّح إليها الكلمات المكتوبة بتخطيط خاطئ.
يكتبها AURA بأحرف كبيرة (TTN)، حتى لو كُتبت بتخطيط خاطئ.
لا يفعل AURA شيئًا في هذه التطبيقات. تُوقَف الألعاب بملء الشاشة تلقائيًا.
عند التبديل إلى أحد هذه التطبيقات، يغيّر AURA التخطيط إلى اللغة المختارة.

hi हिन्दी
चालू
स्वतः सुधार
ध्वनि
⚠︎ अनुमति दें: सुलभता, इनपुट मॉनिटरिंग (Input Monitoring)
ऐप:
इस ऐप में काम न करें
गेम — AURA रुका हुआ
इस ऐप की भाषा
कोई बंधन नहीं
अपवाद
इनमें काम न करें (हाल के ऐप)
भाषा बंधन
खाली
लॉगिन पर शुरू करें
मेरे शब्द…
सहेजें
रद्द करें
मेनू की भाषा
सभी भाषाएँ
यूरोप
काकेशस और मध्य एशिया
मध्य पूर्व
एशिया
सिस्टम
दो बार ⇧ — शब्द/चयन बदलें
समस्या बताएँ…
क्या हुआ और किस ऐप में:
अपडेट जाँचें…
⬆︎ शायद नया अपडेट आया है — जाँचें
AURA Switcher का समर्थन करें ☕
बंद करें
AURA Switcher {v} आ गया है
आपके पास नवीनतम संस्करण है
नया क्या है
अपडेट करें
बाद में
अपने-आप अपडेट नहीं हो सका। डाउनलोड के लिए वेबसाइट खोलें?
AURA Switcher चल रहा है। इसका आइकन नोटिफ़िकेशन एरिया में है; मेनू खोलने के लिए घड़ी के पास ^ पर क्लिक करें
अक्षरों का केस ठीक करें
संक्षिप्त रूप…
⌥ + दो बार ⇧ — केस बदलें
सेटिंग…
सामान्य
शॉर्टकट
शब्द
ऐप्स
के बारे में
शब्द
ऐप
भाषा
खोजें
जोड़ें
हटाएँ
ऐप चुनें…
हाल के ऐप्स
संस्करण
GitHub पर मूल प्रोजेक्ट
इन शॉर्टकट को अभी बदला नहीं जा सकता।
AURA इन शब्दों को कभी नहीं बदलता, और गलत लेआउट में टाइप किए शब्दों को इनमें सुधारता है।
AURA इन्हें बड़े अक्षरों में लिखता है (TTN), भले ही वे गलत लेआउट में टाइप किए गए हों।
इन ऐप्स में AURA कुछ नहीं करता। फ़ुल-स्क्रीन गेम अपने आप रुक जाते हैं।
जब आप इनमें से किसी ऐप पर जाते हैं, AURA लेआउट को चुनी हुई भाषा में बदल देता है।

ko 한국어
켜기
자동 수정
소리
⚠︎ 접근 권한 허용: 손쉬운 사용, 입력 모니터링
앱:
이 앱에서 작동 안 함
게임 — AURA 일시 중지됨
이 앱의 언어
지정 안 함
예외
작동 안 함 (최근 앱)
언어 지정
비어 있음
로그인 시 실행
내 단어…
저장
취소
메뉴 언어
모든 언어
유럽
캅카스·중앙아시아
중동
아시아
시스템
⇧ 두 번 — 단어/선택 영역 변환
문제 신고…
무슨 일이 어느 앱에서 있었나요:
업데이트 확인…
⬆︎ 업데이트가 있을 수 있습니다 — 확인
AURA Switcher 후원하기 ☕
종료
AURA Switcher {v} 출시
최신 버전을 사용 중입니다
새로운 기능
업데이트
나중에
자동으로 업데이트하지 못했습니다. 다운로드하려면 웹사이트를 열까요?
AURA Switcher가 실행 중입니다. 아이콘은 알림 영역에 있습니다. 시계 옆의 ^를 눌러 메뉴를 여세요
대소문자 자동 수정
약어…
⌥ + ⇧ 두 번 — 대소문자 변경
설정…
일반
단축키
단어
앱
정보
단어
앱
언어
검색
추가
제거
앱 선택…
최근 앱
버전
GitHub의 원본 프로젝트
이 단축키는 아직 변경할 수 없습니다.
AURA는 이 단어들을 절대 바꾸지 않으며, 잘못된 자판 배열로 입력한 단어는 이 단어로 고칩니다.
AURA는 이 단어들을 대문자로 씁니다(TTN). 잘못된 자판 배열로 입력해도 마찬가지입니다.
이 앱들에서는 AURA가 아무것도 하지 않습니다. 전체 화면 게임은 자동으로 일시 중지됩니다.
이 앱 중 하나로 전환하면 AURA가 자판 배열을 선택한 언어로 바꿉니다.

be Беларуская
Уключана
Аўтавыпраўленне
Гук
⚠︎ Дайце доступ: Спецыяльныя магчымасці, Input Monitoring
Праграма:
Не працаваць у гэтай праграме
Гульня — AURA на паўзе
Мова для гэтай праграмы
Без прывязкі
Выключэнні
Не працаваць у (нядаўнія праграмы)
Прывязкі моў
Пуста
Запускаць пры ўваходзе
Мае словы…
Захаваць
Скасаваць
Мова меню
Усе мовы
Еўропа
Каўказ і Цэнтральная Азія
Блізкі Усход
Азія
Сістэмная
Падвойны ⇧ — змяніць мову слова/вылучэння
Паведаміць пра праблему…
Што здарылася і ў якой праграме:
Праверыць абнаўленні…
⬆︎ Магчыма, выйшла абнаўленне — праверыць
Падтрымаць AURA Switcher ☕
Выхад
Выйшла AURA Switcher {v}
У вас апошняя версія
Што новага
Абнавіць
Пазней
Не ўдалося абнавіць аўтаматычна. Адкрыць сайт, каб спампаваць?
AURA Switcher працуе. Значок — у вобласці апавяшчэнняў; націсніце ^ побач з гадзіннікам, каб адкрыць меню
Выпраўляць рэгістр
Абрэвіятуры…
⌥ + падвойны ⇧ — змяніць рэгістр
Налады…
Агульныя
Спалучэнні клавіш
Словы
Праграмы
Пра праграму
Слова
Праграма
Мова
Пошук
Дадаць
Выдаліць
Выбраць праграму…
Апошнія праграмы
Версія
Арыгінальны праект на GitHub
Гэтыя спалучэнні пакуль нельга змяніць.
AURA ніколі не змяняе гэтыя словы, а набраныя не ў той раскладцы — выпраўляе на іх.
AURA піша іх вялікімі літарамі (ТТН), нават калі набрана не ў той раскладцы.
У гэтых праграмах AURA нічога не робіць. Поўнаэкранныя гульні спыняюцца аўтаматычна.
Калі вы пераключаецеся на адну з гэтых праграм, AURA змяняе раскладку на абраную мову.

kk Қазақша
Қосулы
Автотүзету
Дыбыс
⚠︎ Рұқсат беріңіз: Арнайы мүмкіндіктер, Input Monitoring
Қолданба:
Бұл қолданбада жұмыс істемеу
Ойын — AURA кідіртілді
Осы қолданбаның тілі
Байланыссыз
Ерекшеліктер
Мында жұмыс істемеу (соңғы қолданбалар)
Тіл байланыстары
Бос
Кіргенде іске қосу
Менің сөздерім…
Сақтау
Бас тарту
Мәзір тілі
Барлық тілдер
Еуропа
Кавказ және Орталық Азия
Таяу Шығыс
Азия
Жүйелік
Қос ⇧ — сөзді/таңдалғанды түрлендіру
Мәселе туралы хабарлау…
Не болды және қай қолданбада:
Жаңартуларды тексеру…
⬆︎ Жаңарту шыққан болуы мүмкін — тексеру
AURA Switcher жобасын қолдау ☕
Шығу
AURA Switcher {v} шықты
Сізде соңғы нұсқа бар
Не жаңалық
Жаңарту
Кейінірек
Автоматты түрде жаңарту мүмкін болмады. Жүктеп алу үшін сайтты ашу керек пе?
AURA Switcher жұмыс істеп тұр. Белгішесі хабарландыру аймағында; мәзірді ашу үшін сағаттың жанындағы ^ түймесін басыңыз
Әріп регистрін түзету
Аббревиатуралар…
⌥ + қос ⇧ — регистрді өзгерту
Баптаулар…
Жалпы
Пернелер тіркесімдері
Сөздер
Қолданбалар
Туралы
Сөз
Қолданба
Тіл
Іздеу
Қосу
Жою
Қолданбаны таңдау…
Соңғы қолданбалар
Нұсқа
GitHub-тағы түпнұсқа жоба
Бұл тіркесімдерді әзірге өзгерту мүмкін емес.
AURA бұл сөздерді ешқашан өзгертпейді, қате пернетақтада терілгенді осыларға түзетеді.
AURA оларды бас әріптермен жазады (ТТН), қате пернетақтада терілсе де.
Бұл қолданбаларда AURA ештеңе істемейді. Толық экранды ойындар автоматты түрде кідіртіледі.
Осы қолданбалардың біріне ауысқанда, AURA пернетақта орналасуын таңдалған тілге ауыстырады.

ky Кыргызча
Күйгүзүлгөн
Авто оңдоо
Үн
⚠︎ Мүмкүнчүлүк бериңиз: Атайын мүмкүнчүлүктөр, Input Monitoring
Колдонмо:
Бул колдонмодо иштебөө
Оюн — AURA тыныгууда
Бул колдонмонун тили
Байланышсыз
Өзгөчөлүктөр
Төмөндө иштебөө (акыркы колдонмолор)
Тил байланыштары
Бош
Кирүүдө иштетүү
Менин сөздөрүм…
Сактоо
Жокко чыгаруу
Меню тили
Бардык тилдер
Европа
Кавказ жана Борбордук Азия
Жакынкы Чыгыш
Азия
Системалык
Кош ⇧ — сөздү/тандалганды өзгөртүү
Көйгөй тууралуу кабарлоо…
Эмне болду жана кайсы колдонмодо:
Жаңыртууларды текшерүү…
⬆︎ Жаңыртуу чыгып калышы мүмкүн — текшерүү
AURA Switcher долбоорун колдоо ☕
Чыгуу
AURA Switcher {v} чыкты
Сизде акыркы версия бар
Эмне жаңы
Жаңыртуу
Кийинчерээк
Автоматтык түрдө жаңыртуу мүмкүн болгон жок. Жүктөп алуу үчүн сайтты ачайынбы?
AURA Switcher иштеп жатат. Сөлөкөтү билдирмелер аймагында; менюну ачуу үчүн сааттын жанындагы ^ баскычын басыңыз
Регистрди оңдоо
Аббревиатуралар…
⌥ + кош ⇧ — регистрди өзгөртүү
Жөндөөлөр…
Жалпы
Ыкчам баскычтар
Сөздөр
Колдонмолор
Жөнүндө
Сөз
Колдонмо
Тил
Издөө
Кошуу
Өчүрүү
Колдонмону тандоо…
Акыркы колдонмолор
Версия
GitHub'дагы түпнуска долбоор
Бул ыкчам баскычтарды азырынча өзгөртүүгө болбойт.
AURA бул сөздөрдү эч качан өзгөртпөйт, туура эмес жайгашууда терилгенди ушуларга оңдойт.
AURA аларды баш тамгалар менен жазат (ТТН), туура эмес жайгашууда терилсе да.
Бул колдонмолордо AURA эч нерсе кылбайт. Толук экрандуу оюндар автоматтык түрдө тындырылат.
Бул колдонмолордун бирине которулганыңызда, AURA жайгашууну тандалган тилге өзгөртөт.

ka ქართული
ჩართულია
ავტოშესწორება
ხმა
⚠︎ მიეცით წვდომა: მისაწვდომობა, Input Monitoring
აპლიკაცია:
ამ აპლიკაციაში არ იმუშაოს
თამაში — AURA დაპაუზებულია
ამ აპლიკაციის ენა
მიბმის გარეშე
გამონაკლისები
არ იმუშაოს (ბოლო აპლიკაციები)
ენების მიბმა
ცარიელია
გაშვება შესვლისას
ჩემი სიტყვები…
შენახვა
გაუქმება
მენიუს ენა
ყველა ენა
ევროპა
კავკასია და ცენტრალური აზია
ახლო აღმოსავლეთი
აზია
სისტემური
ორმაგი ⇧ — სიტყვის/მონიშნულის გადაყვანა
პრობლემის შეტყობინება…
რა მოხდა და რომელ აპლიკაციაში:
განახლებების შემოწმება…
⬆︎ შესაძლოა განახლება გამოვიდა — შეამოწმეთ
AURA Switcher-ის მხარდაჭერა ☕
გასვლა
გამოვიდა AURA Switcher {v}
გაქვთ უახლესი ვერსია
რა არის ახალი
განახლება
მოგვიანებით
ავტომატურად განახლება ვერ მოხერხდა. გავხსნა საიტი ჩამოსატვირთად?
AURA Switcher მუშაობს. ხატულა შეტყობინებების არეშია; მენიუს გასახსნელად დააწკაპუნეთ საათის გვერდით ^-ზე
რეგისტრის გასწორება
აბრევიატურები…
⌥ + ორმაგი ⇧ — რეგისტრის შეცვლა
პარამეტრები…
ზოგადი
მალსახმობები
სიტყვები
აპები
შესახებ
სიტყვა
აპი
ენა
ძიება
დამატება
წაშლა
აპის არჩევა…
ბოლო აპები
ვერსია
ორიგინალური პროექტი GitHub-ზე
ამ მალსახმობების შეცვლა ჯერ შეუძლებელია.
AURA ამ სიტყვებს არასოდეს ცვლის, არასწორ განლაგებაში აკრეფილს კი მათზე ასწორებს.
AURA მათ დიდი ასოებით წერს (TTN), თუნდაც არასწორ განლაგებაში იყოს აკრეფილი.
ამ აპებში AURA არაფერს აკეთებს. სრულეკრანიანი თამაშები ავტომატურად ჩერდება.
როცა ამ აპებიდან რომელიმეზე გადახვალთ, AURA განლაგებას არჩეულ ენაზე ცვლის.

hy Հայերեն
Միացված է
Ինքնաուղղում
Ձայն
⚠︎ Տվեք թույլտվություն՝ Հասանելիություն, Input Monitoring
Հավելված՝
Չաշխատել այս հավելվածում
Խաղ — AURA-ն դադարի վրա է
Այս հավելվածի լեզուն
Առանց կապակցման
Բացառություններ
Չաշխատել (վերջին հավելվածներ)
Լեզուների կապակցումներ
Դատարկ է
Գործարկել մուտքի ժամանակ
Իմ բառերը…
Պահպանել
Չեղարկել
Ցանկի լեզուն
Բոլոր լեզուները
Եվրոպա
Կովկաս և Կենտրոնական Ասիա
Մերձավոր Արևելք
Ասիա
Համակարգային
Կրկնակի ⇧ — փոխարկել բառը/նշվածը
Հաղորդել խնդրի մասին…
Ինչ է պատահել և որ հավելվածում՝
Ստուգել թարմացումները…
⬆︎ Հնարավոր է՝ թարմացում է թողարկվել — ստուգել
Աջակցել AURA Switcher-ին ☕
Ելք
Թողարկվել է AURA Switcher {v}
Դուք ունեք վերջին տարբերակը
Ինչ նոր է
Թարմացնել
Հետո
Չհաջողվեց թարմացնել ավտոմատ կերպով։ Բացե՞լ կայքը՝ ներբեռնելու համար։
AURA Switcher-ը աշխատում է։ Պատկերակը ծանուցումների տարածքում է․ մենյուն բացելու համար սեղմեք ժամացույցի կողքի ^-ը
Ուղղել մեծատառերը
Հապավումներ…
⌥ + կրկնակի ⇧ — փոխել տառերի գրանցումը
Կարգավորումներ…
Ընդհանուր
Դյուրանցումներ
Բառեր
Հավելվածներ
Ծրագրի մասին
Բառ
Հավելված
Լեզու
Որոնել
Ավելացնել
Հեռացնել
Ընտրել հավելված…
Վերջին հավելվածներ
Տարբերակ
Բնօրինակ նախագիծը GitHub-ում
Այս դյուրանցումները դեռ հնարավոր չէ փոխել։
AURA-ն երբեք չի փոխում այս բառերը, իսկ սխալ դասավորությամբ տպվածները ուղղում է դրանց։
AURA-ն դրանք գրում է մեծատառերով (TTN), նույնիսկ եթե տպվել են սխալ դասավորությամբ։
Այս հավելվածներում AURA-ն ոչինչ չի անում։ Լիաէկրան խաղերը ավտոմատ դադարեցվում են։
Երբ անցնում եք այս հավելվածներից մեկին, AURA-ն դասավորությունը փոխում է ընտրված լեզվի։

az Azərbaycan
Aktivdir
Avtomatik düzəliş
Səs
⚠︎ İcazə verin: Əlçatımlılıq, Input Monitoring
Tətbiq:
Bu tətbiqdə işləmə
Oyun — AURA fasilədədir
Bu tətbiq üçün dil
Bağlama yoxdur
İstisnalar
Burada işləmə (son tətbiqlər)
Dil bağlamaları
Boşdur
Girişdə başlat
Mənim sözlərim…
Saxla
Ləğv et
Menyu dili
Bütün dillər
Avropa
Qafqaz və Mərkəzi Asiya
Yaxın Şərq
Asiya
Sistem
Qoşa ⇧ — sözü/seçilmişi çevir
Problem barədə bildir…
Nə baş verdi və hansı tətbiqdə:
Yeniləmələri yoxla…
⬆︎ Yeniləmə çıxmış ola bilər — yoxlayın
AURA Switcher-i dəstəkləyin ☕
Çıxış
AURA Switcher {v} çıxdı
Ən son versiya sizdədir
Nə yenidir
Yenilə
Sonra
Avtomatik yeniləmək alınmadı. Yükləmək üçün sayt açılsın?
AURA Switcher işləyir. Nişan bildiriş sahəsindədir; menyunu açmaq üçün saatın yanındakı ^ işarəsinə klikləyin
Hərf registrini düzəlt
Abreviaturalar…
⌥ + qoşa ⇧ — registri dəyiş
Parametrlər…
Ümumi
Qısayollar
Sözlər
Tətbiqlər
Haqqında
Söz
Tətbiq
Dil
Axtar
Əlavə et
Sil
Tətbiq seç…
Son tətbiqlər
Versiya
GitHub-dakı orijinal layihə
Bu qısayolları hələ dəyişmək olmur.
AURA bu sözləri heç vaxt dəyişmir, səhv düzümdə yığılanları isə bunlara düzəldir.
AURA bunları böyük hərflərlə yazır (TTN), səhv düzümdə yığılsa belə.
Bu tətbiqlərdə AURA heç nə etmir. Tam ekran oyunlar avtomatik dayandırılır.
Bu tətbiqlərdən birinə keçdikdə AURA düzümü seçilmiş dilə dəyişir.

sr Српски
Укључено
Аутокорекција
Звук
⚠︎ Дозволите приступ: Приступачност, Input Monitoring
Апликација:
Не радити у овој апликацији
Игра — AURA паузирана
Језик за ову апликацију
Без повезивања
Изузеци
Не радити у (недавне апликације)
Повезивање језика
Празно
Покрени при пријави
Моје речи…
Сачувај
Откажи
Језик менија
Сви језици
Европа
Кавказ и Централна Азија
Блиски исток
Азија
Системски
Двоструки ⇧ — претвори реч/избор
Пријави проблем…
Шта се догодило и у којој апликацији:
Провери ажурирања…
⬆︎ Можда је изашло ажурирање — провери
Подржи AURA Switcher ☕
Изађи
Изашао је AURA Switcher {v}
Имате најновију верзију
Шта је ново
Ажурирај
Касније
Аутоматско ажурирање није успело. Отворити сајт за преузимање?
AURA Switcher ради. Икона је у пољу за обавештења; кликните на ^ поред сата да бисте отворили мени
Исправи величину слова
Скраћенице…
⌥ + двоструки ⇧ — промени величину слова
Подешавања…
Опште
Пречице
Речи
Апликације
О програму
Реч
Апликација
Језик
Претрага
Додај
Уклони
Изабери апликацију…
Недавне апликације
Верзија
Оригинални пројекат на GitHub-у
Ове пречице се још не могу мењати.
AURA никада не мења ове речи, а откуцане у погрешном распореду исправља на њих.
AURA их пише великим словима (ТТН), чак и ако су откуцане у погрешном распореду.
У овим апликацијама AURA не ради ништа. Игре преко целог екрана се аутоматски паузирају.
Када пређете на једну од ових апликација, AURA мења распоред на изабрани језик.

mk Македонски
Вклучено
Автокорекција
Звук
⚠︎ Дозволете пристап: Пристапност, Input Monitoring
Апликација:
Не работи во оваа апликација
Игра — AURA паузирана
Јазик за оваа апликација
Без врзување
Исклучоци
Не работи во (неодамнешни апликации)
Врзувања на јазици
Празно
Стартувај при најава
Моите зборови…
Зачувај
Откажи
Јазик на менито
Сите јазици
Европа
Кавказ и Централна Азија
Блиски Исток
Азија
Системски
Двоен ⇧ — претвори збор/избор
Пријави проблем…
Што се случи и во која апликација:
Провери за ажурирања…
⬆︎ Можеби има ново ажурирање — провери
Поддржи го AURA Switcher ☕
Излези
Излезе AURA Switcher {v}
Ја имате најновата верзија
Што е ново
Ажурирај
Подоцна
Автоматското ажурирање не успеа. Да го отворам сајтот за преземање?
AURA Switcher работи. Иконата е во областа за известувања; кликнете на ^ покрај часовникот за да го отворите менито
Поправи големи/мали букви
Кратенки…
⌥ + двоен ⇧ — промени големи/мали букви
Поставки…
Општо
Кратенки на тастатура
Зборови
Апликации
За апликацијата
Збор
Апликација
Јазик
Пребарај
Додај
Отстрани
Избери апликација…
Неодамнешни апликации
Верзија
Оригиналниот проект на GitHub
Овие кратенки засега не можат да се менуваат.
AURA никогаш не ги менува овие зборови, а напишаните во погрешен распоред ги поправа на нив.
AURA ги пишува со големи букви (ТТН), дури и ако се напишани во погрешен распоред.
Во овие апликации AURA не прави ништо. Игрите на цел екран автоматски се паузираат.
Кога ќе преминете на една од овие апликации, AURA го менува распоредот на избраниот јазик.

sk Slovenčina
Zapnuté
Automatické opravy
Zvuk
⚠︎ Povoľte prístup: Zjednodušenie ovládania, Monitorovanie vstupu (Input Monitoring)
Aplikácia:
V tejto aplikácii nepracovať
Hra — AURA pozastavená
Jazyk pre túto aplikáciu
Bez priradenia
Výnimky
Nepracovať v (nedávne aplikácie)
Priradenia jazykov
Prázdne
Spúšťať po prihlásení
Moje slová…
Uložiť
Zrušiť
Jazyk ponuky
Všetky jazyky
Európa
Kaukaz a Stredná Ázia
Blízky východ
Ázia
Systémový
Dvojitý ⇧ — previesť slovo/výber
Nahlásiť problém…
Čo sa stalo a v ktorej aplikácii:
Skontrolovať aktualizácie…
⬆︎ Možno vyšla aktualizácia — skontrolovať
Podporiť AURA Switcher ☕
Ukončiť
Vyšiel AURA Switcher {v}
Máte najnovšiu verziu
Čo je nové
Aktualizovať
Neskôr
Automatická aktualizácia sa nepodarila. Otvoriť web na stiahnutie?
AURA Switcher beží. Ikona je v oblasti oznámení; ponuku otvoríte kliknutím na ^ vedľa hodín
Opravovať veľkosť písmen
Skratky…
⌥ + dvojitý ⇧ — zmeniť veľkosť písmen
Nastavenia…
Všeobecné
Skratky
Slová
Aplikácie
O aplikácii
Slovo
Aplikácia
Jazyk
Hľadať
Pridať
Odstrániť
Vybrať aplikáciu…
Posledné aplikácie
Verzia
Pôvodný projekt na GitHube
Tieto skratky zatiaľ nemožno zmeniť.
AURA tieto slová nikdy nemení a slová napísané v nesprávnom rozložení opraví na ne.
AURA ich píše veľkými písmenami (TTN), aj keď boli napísané v nesprávnom rozložení.
V týchto aplikáciách AURA nič nerobí. Celoobrazovkové hry sa pozastavia automaticky.
Keď prepnete na jednu z týchto aplikácií, AURA zmení rozloženie na vybraný jazyk.

hr Hrvatski
Uključeno
Automatski ispravak
Zvuk
⚠︎ Dopustite pristup: Pristupačnost, Praćenje unosa (Input Monitoring)
Aplikacija:
Ne radi u ovoj aplikaciji
Igra — AURA pauzirana
Jezik za ovu aplikaciju
Bez povezivanja
Iznimke
Ne radi u (nedavne aplikacije)
Povezivanja jezika
Prazno
Pokreni pri prijavi
Moje riječi…
Spremi
Odustani
Jezik izbornika
Svi jezici
Europa
Kavkaz i Srednja Azija
Bliski istok
Azija
Sustavski
Dvostruki ⇧ — pretvori riječ/odabir
Prijavi problem…
Što se dogodilo i u kojoj aplikaciji:
Provjeri ažuriranja…
⬆︎ Možda je izašlo ažuriranje — provjeri
Podrži AURA Switcher ☕
Izađi
Izašao je AURA Switcher {v}
Imate najnoviju verziju
Što je novo
Ažuriraj
Kasnije
Automatsko ažuriranje nije uspjelo. Otvoriti web-stranicu za preuzimanje?
AURA Switcher radi. Ikona je u području obavijesti; kliknite ^ pored sata da otvorite izbornik
Ispravi velika/mala slova
Kratice…
⌥ + dvostruki ⇧ — promijeni velika/mala slova
Postavke…
Općenito
Prečaci
Riječi
Aplikacije
O aplikaciji
Riječ
Aplikacija
Jezik
Traži
Dodaj
Ukloni
Odaberi aplikaciju…
Nedavne aplikacije
Verzija
Izvorni projekt na GitHubu
Ti se prečaci još ne mogu mijenjati.
AURA nikada ne mijenja ove riječi, a utipkane u krivom rasporedu ispravlja u njih.
AURA ih piše velikim slovima (TTN), čak i ako su utipkane u krivom rasporedu.
U tim aplikacijama AURA ne radi ništa. Igre preko cijelog zaslona automatski se pauziraju.
Kad prijeđete na jednu od tih aplikacija, AURA mijenja raspored na odabrani jezik.

sl Slovenščina
Vklopljeno
Samodejni popravki
Zvok
⚠︎ Dovolite dostop: Dostopnost, Input Monitoring
Aplikacija:
V tej aplikaciji ne delajte
Igra — AURA zaustavljena
Jezik za to aplikacijo
Brez povezave
Izjeme
Ne delajte v (nedavne aplikacije)
Povezave jezikov
Prazno
Zaženi ob prijavi
Moje besede…
Shrani
Prekliči
Jezik menija
Vsi jeziki
Evropa
Kavkaz in Srednja Azija
Bližnji vzhod
Azija
Sistemski
Dvojni ⇧ — pretvori besedo/izbor
Prijavi težavo…
Kaj se je zgodilo in v kateri aplikaciji:
Preverite posodobitve…
⬆︎ Morda je izšla posodobitev — preverite
Podpri AURA Switcher ☕
Končaj
Izšel je AURA Switcher {v}
Imate najnovejšo različico
Kaj je novega
Posodobi
Pozneje
Samodejna posodobitev ni uspela. Odprem spletno mesto za prenos?
AURA Switcher deluje. Ikona je v območju za obvestila; kliknite ^ ob uri, da odprete meni
Popravi velike/male črke
Kratice…
⌥ + dvojni ⇧ — spremeni velike/male črke
Nastavitve…
Splošno
Bližnjice
Besede
Aplikacije
O programu
Beseda
Aplikacija
Jezik
Iskanje
Dodaj
Odstrani
Izberi aplikacijo…
Nedavne aplikacije
Različica
Izvirni projekt na GitHubu
Teh bližnjic še ni mogoče spreminjati.
AURA teh besed nikoli ne spreminja, natipkane v napačni postavitvi pa popravi vanje.
AURA jih piše z velikimi črkami (TTN), tudi če so natipkane v napačni postavitvi.
V teh aplikacijah AURA ne naredi ničesar. Igre čez cel zaslon se samodejno začasno ustavijo.
Ko preklopite na eno od teh aplikacij, AURA spremeni postavitev na izbrani jezik.

lt Lietuvių
Įjungta
Automatinis taisymas
Garsas
⚠︎ Suteikite prieigą: Pritaikymas neįgaliesiems, Input Monitoring
Programa:
Šioje programoje nedirbti
Žaidimas — AURA pristabdyta
Kalba šiai programai
Be priskyrimo
Išimtys
Nedirbti (naujausios programos)
Kalbų priskyrimai
Tuščia
Paleisti prisijungiant
Mano žodžiai…
Išsaugoti
Atšaukti
Meniu kalba
Visos kalbos
Europa
Kaukazas ir Vidurio Azija
Artimieji Rytai
Azija
Sistemos
Dvigubas ⇧ — konvertuoti žodį/pažymėtą tekstą
Pranešti apie problemą…
Kas nutiko ir kurioje programoje:
Tikrinti naujinimus…
⬆︎ Galbūt išleistas naujinimas — patikrinkite
Paremti AURA Switcher ☕
Išeiti
Išleistas AURA Switcher {v}
Turite naujausią versiją
Kas naujo
Atnaujinti
Vėliau
Nepavyko atnaujinti automatiškai. Atidaryti svetainę atsisiuntimui?
AURA Switcher veikia. Piktograma yra pranešimų srityje; spustelėkite ^ šalia laikrodžio, kad atidarytumėte meniu
Taisyti didžiąsias/mažąsias raides
Santrumpos…
⌥ + dvigubas ⇧ — keisti raidžių dydį
Nustatymai…
Bendra
Spartieji klavišai
Žodžiai
Programos
Apie
Žodis
Programa
Kalba
Ieškoti
Pridėti
Pašalinti
Pasirinkti programą…
Naujausios programos
Versija
Originalus projektas „GitHub“
Šių spartųjų klavišų kol kas negalima keisti.
AURA niekada nekeičia šių žodžių, o netinkamu išdėstymu surinktus pataiso į juos.
AURA juos rašo didžiosiomis raidėmis (TTN), net jei jie surinkti netinkamu išdėstymu.
Šiose programose AURA nieko nedaro. Viso ekrano žaidimai pristabdomi automatiškai.
Perjungus į vieną iš šių programų, AURA pakeičia išdėstymą į pasirinktą kalbą.

lv Latviešu
Ieslēgts
Automātiskā labošana
Skaņa
⚠︎ Atļaujiet piekļuvi: Pieejamība, Input Monitoring
Lietotne:
Šajā lietotnē nedarboties
Spēle — AURA apturēta
Valoda šai lietotnei
Bez piesaistes
Izņēmumi
Nedarboties (nesenās lietotnes)
Valodu piesaistes
Tukšs
Palaist pieteikšanās brīdī
Mani vārdi…
Saglabāt
Atcelt
Izvēlnes valoda
Visas valodas
Eiropa
Kaukāzs un Centrālāzija
Tuvie Austrumi
Āzija
Sistēmas
Dubults ⇧ — pārvērst vārdu/atlasi
Ziņot par problēmu…
Kas notika un kurā lietotnē:
Meklēt atjauninājumus…
⬆︎ Iespējams, iznācis atjauninājums — pārbaudīt
Atbalstīt AURA Switcher ☕
Iziet
Iznācis AURA Switcher {v}
Jums ir jaunākā versija
Kas jauns
Atjaunināt
Vēlāk
Automātiski atjaunināt neizdevās. Atvērt vietni lejupielādei?
AURA Switcher darbojas. Ikona ir paziņojumu apgabalā; noklikšķiniet uz ^ blakus pulkstenim, lai atvērtu izvēlni
Labot lielos/mazos burtus
Saīsinājumi…
⌥ + dubults ⇧ — mainīt burtu reģistru
Iestatījumi…
Vispārīgi
Īsinājumtaustiņi
Vārdi
Lietotnes
Par programmu
Vārds
Lietotne
Valoda
Meklēt
Pievienot
Noņemt
Izvēlēties lietotni…
Pēdējās lietotnes
Versija
Oriģinālais projekts GitHub
Šos īsinājumtaustiņus vēl nevar mainīt.
AURA šos vārdus nekad nemaina, bet nepareizā izkārtojumā ievadītos izlabo uz tiem.
AURA tos raksta ar lielajiem burtiem (TTN), pat ja tie ievadīti nepareizā izkārtojumā.
Šajās lietotnēs AURA neko nedara. Pilnekrāna spēles tiek automātiski apturētas.
Kad pārslēdzaties uz kādu no šīm lietotnēm, AURA nomaina izkārtojumu uz izvēlēto valodu.

et Eesti
Sees
Automaatne parandus
Heli
⚠︎ Andke juurdepääs: Juurdepääsetavus, Input Monitoring
Rakendus:
Selles rakenduses mitte töötada
Mäng — AURA peatatud
Selle rakenduse keel
Seostamata
Erandid
Mitte töötada (hiljutised rakendused)
Keeleseosed
Tühi
Käivita sisselogimisel
Minu sõnad…
Salvesta
Tühista
Menüü keel
Kõik keeled
Euroopa
Kaukaasia ja Kesk-Aasia
Lähis-Ida
Aasia
Süsteemne
Topelt ⇧ — teisenda sõna/valik
Teata probleemist…
Mis juhtus ja millises rakenduses:
Otsi uuendusi…
⬆︎ Uuendus võib olla saadaval — kontrolli
Toeta AURA Switcherit ☕
Välju
AURA Switcher {v} on väljas
Sul on uusim versioon
Mis on uut
Uuenda
Hiljem
Automaatne uuendamine ebaõnnestus. Avada veebileht allalaadimiseks?
AURA Switcher töötab. Ikoon on teavitusalas; menüü avamiseks klõpsake kella kõrval ^
Paranda suur-/väiketähti
Lühendid…
⌥ + topelt ⇧ — muuda tähesuurust
Seaded…
Üldine
Kiirklahvid
Sõnad
Rakendused
Teave
Sõna
Rakendus
Keel
Otsi
Lisa
Eemalda
Vali rakendus…
Hiljutised rakendused
Versioon
Algne projekt GitHubis
Neid kiirklahve ei saa veel muuta.
AURA ei muuda neid sõnu kunagi ja parandab vales paigutuses trükitud sõnad nendeks.
AURA kirjutab need suurtähtedega (TTN), isegi kui need on trükitud vales paigutuses.
Nendes rakendustes AURA midagi ei tee. Täisekraanimängud peatatakse automaatselt.
Kui lülitud ühele neist rakendustest, muudab AURA paigutuse valitud keeleks.

da Dansk
Aktiveret
Automatisk rettelse
Lyd
⚠︎ Giv adgang: Tilgængelighed, Inputovervågning (Input Monitoring)
App:
Deaktiver i denne app
Spil — AURA på pause
Sprog for denne app
Ingen tilknytning
Undtagelser
Deaktiver i (seneste apps)
Sprogtilknytninger
Tom
Start ved login
Mine ord…
Gem
Annuller
Menusprog
Alle sprog
Europa
Kaukasus og Centralasien
Mellemøsten
Asien
System
Dobbelt ⇧ — konvertér ord/markering
Rapportér et problem…
Hvad skete der, og i hvilken app:
Søg efter opdateringer…
⬆︎ Der kan være en opdatering — tjek
Støt AURA Switcher ☕
Afslut
AURA Switcher {v} er udkommet
Du har den nyeste version
Nyheder
Opdater
Senere
Kunne ikke opdatere automatisk. Åbn hjemmesiden for at hente den?
AURA Switcher kører. Ikonet er i meddelelsesområdet; klik på ^ ved siden af uret for at åbne menuen
Ret store/små bogstaver
Forkortelser…
⌥ + dobbelt ⇧ — skift store/små bogstaver
Indstillinger…
Generelt
Genveje
Ord
Apps
Om
Ord
App
Sprog
Søg
Tilføj
Fjern
Vælg app…
Seneste apps
Version
Det oprindelige projekt på GitHub
Disse genveje kan endnu ikke ændres.
AURA ændrer aldrig disse ord og retter ord skrevet i forkert layout til dem.
AURA skriver dem med store bogstaver (TTN), selv hvis de er skrevet i det forkerte layout.
AURA gør ingenting i disse apps. Fuldskærmsspil sættes automatisk på pause.
Når du skifter til en af disse apps, skifter AURA layout til det valgte sprog.

nb Norsk bokmål
På
Autokorrigering
Lyd
⚠︎ Gi tilgang: Tilgjengelighet, Inndataovervåking (Input Monitoring)
App:
Ikke aktiv i denne appen
Spill — AURA er satt på pause
Språk for denne appen
Ingen kobling
Unntak
Ikke aktiv i (nylige apper)
Språkkoblinger
Tom
Start ved innlogging
Mine ord…
Lagre
Avbryt
Menyspråk
Alle språk
Europa
Kaukasus og Sentral-Asia
Midtøsten
Asia
System
Dobbel ⇧ — konverter ord/markering
Rapporter et problem…
Hva skjedde, og i hvilken app:
Se etter oppdateringer…
⬆︎ En oppdatering kan være tilgjengelig — sjekk
Støtt AURA Switcher ☕
Avslutt
AURA Switcher {v} er ute
Du har den nyeste versjonen
Nytt
Oppdater
Senere
Kunne ikke oppdatere automatisk. Åpne nettstedet for å laste den ned?
AURA Switcher kjører. Ikonet er i varslingsfeltet; klikk på ^ ved siden av klokken for å åpne menyen
Rett store/små bokstaver
Forkortelser…
⌥ + dobbel ⇧ — bytt store/små bokstaver
Innstillinger…
Generelt
Snarveier
Ord
Apper
Om
Ord
App
Språk
Søk
Legg til
Fjern
Velg app…
Nylige apper
Versjon
Det opprinnelige prosjektet på GitHub
Disse snarveiene kan ikke endres ennå.
AURA endrer aldri disse ordene og retter ord skrevet i feil layout til dem.
AURA skriver dem med store bokstaver (TTN), selv om de er skrevet i feil layout.
AURA gjør ingenting i disse appene. Fullskjermspill settes automatisk på pause.
Når du bytter til en av disse appene, bytter AURA layout til det valgte språket.

is Íslenska
Kveikt
Sjálfvirk leiðrétting
Hljóð
⚠︎ Veittu aðgang: Algildur aðgangur, Input Monitoring
Forrit:
Ekki virkt í þessu forriti
Leikur — AURA í bið
Tungumál fyrir þetta forrit
Engin tenging
Undantekningar
Ekki virkt í (nýleg forrit)
Tungumálatengingar
Tómt
Ræsa við innskráningu
Mín orð…
Vista
Hætta við
Tungumál valmyndar
Öll tungumál
Evrópa
Kákasus og Mið-Asía
Mið-Austurlönd
Asía
Kerfið
Tvöfalt ⇧ — umbreyta orði/vali
Tilkynna vandamál…
Hvað gerðist og í hvaða forriti:
Athuga með uppfærslur…
⬆︎ Uppfærsla gæti verið tiltæk — athuga
Styðja AURA Switcher ☕
Hætta
AURA Switcher {v} er komið út
Þú ert með nýjustu útgáfuna
Hvað er nýtt
Uppfæra
Síðar
Ekki tókst að uppfæra sjálfkrafa. Opna vefsíðuna til að sækja hana?
AURA Switcher er í gangi. Táknið er á tilkynningasvæðinu; smelltu á ^ við hliðina á klukkunni til að opna valmyndina
Laga há-/lágstafi
Skammstafanir…
⌥ + tvöfalt ⇧ — breyta há-/lágstöfum
Stillingar…
Almennt
Flýtilyklar
Orð
Forrit
Um
Orð
Forrit
Tungumál
Leita
Bæta við
Fjarlægja
Velja forrit…
Nýleg forrit
Útgáfa
Upprunalega verkefnið á GitHub
Ekki er enn hægt að breyta þessum flýtilyklum.
AURA breytir þessum orðum aldrei og leiðréttir orð sem slegin eru inn í röngu skipulagi í þau.
AURA skrifar þau með hástöfum (TTN), jafnvel þótt þau séu slegin inn í röngu skipulagi.
AURA gerir ekkert í þessum forritum. Leikir í öllum skjánum eru settir sjálfkrafa á bið.
Þegar þú skiptir yfir í eitt þessara forrita breytir AURA skipulaginu í valið tungumál.

sq Shqip
Aktivizuar
Korrigjim automatik
Zëri
⚠︎ Jepni qasje: Përdorimi i lehtë, Input Monitoring
Aplikacioni:
Mos vepro në këtë aplikacion
Lojë — AURA në pauzë
Gjuha për këtë aplikacion
Pa lidhje
Përjashtime
Mos vepro në (aplikacionet e fundit)
Lidhjet e gjuhëve
Bosh
Hap në hyrje
Fjalët e mia…
Ruaj
Anulo
Gjuha e menysë
Të gjitha gjuhët
Evropa
Kaukazi dhe Azia Qendrore
Lindja e Mesme
Azia
Sistemi
Dyfishi ⇧ — konverto fjalën/përzgjedhjen
Raporto një problem…
Çfarë ndodhi dhe në cilin aplikacion:
Kontrollo për përditësime…
⬆︎ Mund të ketë një përditësim — kontrollo
Mbështet AURA Switcher ☕
Mbyll
AURA Switcher {v} doli
Keni versionin më të ri
Çfarë ka të re
Përditëso
Më vonë
Nuk u përditësua automatikisht. Të hapet faqja e internetit për ta shkarkuar?
AURA Switcher po funksionon. Ikona është në zonën e njoftimeve; kliko ^ pranë orës për të hapur menynë
Korrigjo shkronjat e mëdha/vogla
Shkurtesa…
⌥ + dyfishi ⇧ — ndrysho shkronjat e mëdha/vogla
Cilësimet…
Të përgjithshme
Shkurtoret
Fjalët
Aplikacionet
Rreth
Fjala
Aplikacioni
Gjuha
Kërko
Shto
Hiq
Zgjidh aplikacion…
Aplikacionet e fundit
Versioni
Projekti origjinal në GitHub
Këto shkurtore nuk mund të ndryshohen ende.
AURA nuk i ndryshon kurrë këto fjalë dhe i korrigjon në to ato që janë shkruar në pamje të gabuar.
AURA i shkruan me shkronja të mëdha (TTN), edhe kur janë shkruar në pamje të gabuar.
Në këto aplikacione AURA nuk bën asgjë. Lojërat me ekran të plotë ndalen automatikisht.
Kur kalon te një nga këto aplikacione, AURA ndryshon pamjen e tastierës në gjuhën e zgjedhur.

fa فارسی
روشن
تصحیح خودکار
صدا
⚠︎ دسترسی بدهید: دسترسی‌پذیری، Input Monitoring
برنامه:
در این برنامه کار نکن
بازی — AURA متوقف است
زبان این برنامه
بدون اتصال
استثناها
در این‌ها کار نکن (برنامه‌های اخیر)
اتصال زبان‌ها
خالی
اجرا هنگام ورود
واژه‌های من…
ذخیره
لغو
زبان منو
همه زبان‌ها
اروپا
قفقاز و آسیای مرکزی
خاورمیانه
آسیا
سیستم
دوبار ⇧ — تبدیل واژه/انتخاب
گزارش مشکل…
چه اتفاقی افتاد و در کدام برنامه:
بررسی به‌روزرسانی…
⬆︎ ممکن است به‌روزرسانی موجود باشد — بررسی کنید
حمایت از AURA Switcher ☕
خروج
AURA Switcher {v} منتشر شد
جدیدترین نسخه را دارید
چه چیز تازه است
به‌روزرسانی
بعداً
به‌روزرسانی خودکار انجام نشد. وب‌سایت برای دانلود باز شود؟
AURA Switcher در حال اجراست. نماد آن در ناحیه اعلان‌هاست؛ برای باز کردن منو روی ^ کنار ساعت کلیک کنید
اصلاح حروف بزرگ/کوچک
اختصارات…
⌥ + ⇧ دوبار — تغییر حروف بزرگ/کوچک
تنظیمات…
عمومی
میانبرها
واژه‌ها
برنامه‌ها
درباره
واژه
برنامه
زبان
جستجو
افزودن
حذف
انتخاب برنامه…
برنامه‌های اخیر
نسخه
پروژه اصلی در GitHub
این میانبرها هنوز قابل تغییر نیستند.
AURA هرگز این واژه‌ها را تغییر نمی‌دهد و واژه‌های تایپ‌شده با چیدمان اشتباه را به آن‌ها اصلاح می‌کند.
AURA این‌ها را با حروف بزرگ می‌نویسد (TTN)، حتی اگر با چیدمان اشتباه تایپ شده باشند.
در این برنامه‌ها AURA کاری نمی‌کند. بازی‌های تمام‌صفحه به‌طور خودکار متوقف می‌شوند.
وقتی به یکی از این برنامه‌ها می‌روید، AURA چیدمان را به زبان انتخابی تغییر می‌دهد.

vi Tiếng Việt
Bật
Tự động sửa
Âm thanh
⚠︎ Cấp quyền: Trợ năng, Giám sát đầu vào (Input Monitoring)
Ứng dụng:
Không hoạt động trong ứng dụng này
Trò chơi — AURA tạm dừng
Ngôn ngữ cho ứng dụng này
Chưa gán
Ngoại lệ
Không hoạt động trong (ứng dụng gần đây)
Gán ngôn ngữ
Trống
Chạy khi đăng nhập
Từ của tôi…
Lưu
Hủy
Ngôn ngữ menu
Tất cả ngôn ngữ
Châu Âu
Kavkaz và Trung Á
Trung Đông
Châu Á
Hệ thống
Nhấn đôi ⇧ — chuyển đổi từ/vùng chọn
Báo cáo sự cố…
Chuyện gì đã xảy ra và trong ứng dụng nào:
Kiểm tra cập nhật…
⬆︎ Có thể có bản cập nhật — kiểm tra
Ủng hộ AURA Switcher ☕
Thoát
AURA Switcher {v} đã ra mắt
Bạn đang dùng phiên bản mới nhất
Có gì mới
Cập nhật
Để sau
Không thể tự động cập nhật. Mở trang web để tải về?
AURA Switcher đang chạy. Biểu tượng nằm ở khu vực thông báo; bấm ^ cạnh đồng hồ để mở menu
Sửa chữ hoa/thường
Từ viết tắt…
⌥ + nhấn đôi ⇧ — đổi chữ hoa/thường
Cài đặt…
Chung
Phím tắt
Từ
Ứng dụng
Giới thiệu
Từ
Ứng dụng
Ngôn ngữ
Tìm kiếm
Thêm
Xóa
Chọn ứng dụng…
Ứng dụng gần đây
Phiên bản
Dự án gốc trên GitHub
Chưa thể thay đổi các phím tắt này.
AURA không bao giờ thay đổi các từ này, và sửa sang chúng những từ gõ sai bố cục.
AURA viết hoa chúng (TTN), kể cả khi gõ sai bố cục bàn phím.
AURA không làm gì trong các ứng dụng này. Trò chơi toàn màn hình tự động tạm dừng.
Khi bạn chuyển sang một trong các ứng dụng này, AURA đổi bố cục sang ngôn ngữ đã chọn.

tg Тоҷикӣ
Фаъол
Ислоҳи худкор
Овоз
⚠︎ Дастрасӣ диҳед: Дастрасии универсалӣ, Input Monitoring
Барнома:
Дар ин барнома кор накунед
Бозӣ — AURA таваққуф шудааст
Забон барои ин барнома
Бе пайвастшавӣ
Истисноҳо
Кор накунед дар (барномаҳои охирин)
Пайвасткунии забонҳо
Холӣ
Оғоз ҳангоми воридшавӣ
Калимаҳои ман…
Захира кардан
Бекор кардан
Забони меню
Ҳамаи забонҳо
Аврупо
Қафқоз ва Осиёи Марказӣ
Шарқи Наздик
Осиё
Система
Дукарата ⇧ — табдили калима/интихоб
Хабар додан дар бораи мушкилот…
Чӣ шуд ва дар кадом барнома:
Санҷиши навсозиҳо…
⬆︎ Шояд навсозӣ мавҷуд бошад — санҷед
Дастгирии AURA Switcher ☕
Баромадан
AURA Switcher {v} баромад
Шумо навтарин версияро доред
Чӣ нав аст
Навсозӣ
Баъдтар
Навсозии худкор муяссар нашуд. Сайтро барои боргирӣ кушоед?
AURA Switcher кор карда истодааст. Нишона дар минтақаи огоҳиҳост; барои кушодани меню ^-ро дар назди соат пахш кунед
Ислоҳи ҳарфи калон/хурд
Ихтисораҳо…
⌥ + дукарата ⇧ — иваз кардани ҳарфҳои калон/хурд
Танзимот…
Умумӣ
Тугмаҳои тез
Калимаҳо
Барномаҳо
Дар бораи барнома
Калима
Барнома
Забон
Ҷустуҷӯ
Илова кардан
Тоза кардан
Интихоби барнома…
Барномаҳои охирин
Версия
Лоиҳаи аслӣ дар GitHub
Ин тугмаҳои тезро ҳоло иваз кардан мумкин нест.
AURA ин калимаҳоро ҳаргиз иваз намекунад ва калимаҳои дар тарҳбандии нодуруст навишташударо ба онҳо ислоҳ мекунад.
AURA онҳоро бо ҳарфҳои калон менависад (ТТН), ҳатто агар дар тарҳбандии нодуруст навишта шуда бошанд.
Дар ин барномаҳо AURA коре намекунад. Бозиҳои экрани пурра худкор қатъ мешаванд.
Вақте ба яке аз ин барномаҳо мегузаред, AURA тарҳбандиро ба забони интихобшуда иваз мекунад.

mn Монгол
Идэвхтэй
Автомат засвар
Дуу
⚠︎ Хандалт өгнө үү: Хүртээмж, Input Monitoring
Апп:
Энэ аппад ажиллахгүй
Тоглоом — AURA түр зогссон
Энэ аппын хэл
Холбоогүй
Үл хамаарах зүйлс
Ажиллахгүй (сүүлийн аппууд)
Хэлний холболтууд
Хоосон
Нэвтрэхэд эхлүүлэх
Миний үгс…
Хадгалах
Цуцлах
Цэсний хэл
Бүх хэл
Европ
Кавказ ба Төв Ази
Ойрхи Дорнод
Ази
Систем
Давхар ⇧ — үг/сонголтыг хөрвүүлэх
Асуудлын талаар мэдээлэх…
Юу болсон, ямар аппад:
Шинэчлэлт шалгах…
⬆︎ Шинэчлэлт байж магадгүй — шалгах
AURA Switcher-ийг дэмжих ☕
Гарах
AURA Switcher {v} гарлаа
Танд хамгийн сүүлийн хувилбар байна
Шинэ зүйл
Шинэчлэх
Дараа
Автоматаар шинэчилж чадсангүй. Татаж авахын тулд вэбсайтыг нээх үү?
AURA Switcher ажиллаж байна. Дүрс тэмдэг мэдэгдлийн хэсэгт байна; цэсийг нээхийн тулд цагийн хажууох ^-г дарна уу
Том/жижиг үсгийг засах
Товчлолууд…
⌥ + давхар ⇧ — том/жижиг үсэг солих
Тохиргоо…
Ерөнхий
Товчлолууд
Үгс
Апп-ууд
Тухай
Үг
Апп
Хэл
Хайх
Нэмэх
Хасах
Апп сонгох…
Сүүлийн апп-ууд
Хувилбар
GitHub дээрх эх төсөл
Эдгээр товчлолыг одоогоор өөрчлөх боломжгүй.
AURA эдгээр үгийг хэзээ ч өөрчилдөггүй, буруу байрлалд бичсэнийг тэдгээр рүү засна.
AURA тэдгээрийг том үсгээр бичнэ (ТТН), буруу байрлалд бичсэн ч гэсэн.
Эдгээр апп-д AURA юу ч хийхгүй. Бүтэн дэлгэцийн тоглоомууд автоматаар түр зогсоно.
Эдгээр апп-ын аль нэг рүү шилжихэд AURA байрлалыг сонгосон хэл рүү солино.

tt Татарча
Кабызылган
Автоматик төзәтү
Тавыш
⚠︎ Кереп җитү рөхсәт итегез: Махсус мөмкинлекләр, Input Monitoring
Кушымта:
Бу кушымтада эшләмәскә
Уен — AURA туктатылган
Бу кушымта өчен тел
Бәйләнешсез
Аерымлыклар
Эшләмәскә (соңгы кушымталар)
Телләр бәйләнеше
Буш
Керүдә эшләтеп җибәрергә
Минем сүзләр…
Саклау
Баш тарту
Меню теле
Барлык телләр
Европа
Кавказ һәм Үзәк Азия
Якын Көнчыгыш
Азия
Система
Икеләтә ⇧ — сүзне/сайланганны әйләндерү
Проблема турында хәбәр итү…
Нәрсә булды һәм кайсы кушымтада:
Яңартуларны тикшерү…
⬆︎ Яңарту булырга мөмкин — тикшерегез
AURA Switcher'ны хупларга ☕
Чыгу
AURA Switcher {v} чыкты
Сездә иң соңгы версия
Нәрсә яңа
Яңарту
Соңрак
Автоматик рәвештә яңартып булмады. Йөкләү өчен сайтны ачарга?
AURA Switcher эшли. Билгечә белдерүләр өлкәсендә; менюны ачу өчен сәгать янындагы ^ төймәсенә басыгыз
Хәреф регистрын төзәтү
Кыскартмалар…
⌥ + икеләтә ⇧ — регистрны үзгәртү
Көйләүләр…
Гомуми
Кыска юллар
Сүзләр
Кушымталар
Программа турында
Сүз
Кушымта
Тел
Эзләү
Өстәү
Бетерү
Кушымтаны сайлау…
Соңгы кушымталар
Версия
GitHub'тагы төп проект
Бу кыска юлларны әлегә үзгәртеп булмый.
AURA бу сүзләрне беркайчан да үзгәртми, ә ялгыш рәвештә җыелганнарны шуларга төзәтә.
AURA аларны зур хәрефләр белән яза (ТТН), ялгыш рәвештә җыелса да.
Бу кушымталарда AURA берни эшләми. Тулы экранлы уеннар автоматик туктатыла.
Бу кушымталарның берсенә күчкәндә, AURA рәвешне сайланган телгә үзгәртә.

uz Oʻzbek
Yoqilgan
Avtomatik tuzatish
Tovush
⚠︎ Ruxsat bering: Maxsus imkoniyatlar, Input Monitoring
Ilova:
Bu ilovada ishlamasin
Oʻyin — AURA pauzada
Bu ilova uchun til
Bogʻlanmagan
Istisnolar
Ishlamasin (soʻnggi ilovalar)
Til bogʻlanishlari
Boʻsh
Kirishda ishga tushirish
Mening soʻzlarim…
Saqlash
Bekor qilish
Menyu tili
Barcha tillar
Yevropa
Kavkaz va Markaziy Osiyo
Yaqin Sharq
Osiyo
Tizim
Ikki marta ⇧ — soʻz/belgilashni aylantirish
Muammo haqida xabar berish…
Nima boʻldi va qaysi ilovada:
Yangilanishlarni tekshirish…
⬆︎ Yangilanish boʻlishi mumkin — tekshiring
AURA Switcher’ni qoʻllab-quvvatlash ☕
Chiqish
AURA Switcher {v} chiqdi
Sizda eng soʻnggi versiya bor
Yangiliklar
Yangilash
Keyinroq
Avtomatik yangilab boʻlmadi. Yuklab olish uchun saytni ochaymi?
AURA Switcher ishlayapti. Belgisi bildirishnomalar hududida; menyuni ochish uchun soat yonidagi ^ belgisini bosing
Harf registrini tuzatish
Qisqartmalar…
⌥ + ikki marta ⇧ — registrni oʻzgartirish
Sozlamalar…
Umumiy
Tezkor tugmalar
Soʻzlar
Ilovalar
Dastur haqida
Soʻz
Ilova
Til
Qidirish
Qoʻshish
Olib tashlash
Ilovani tanlash…
Oxirgi ilovalar
Versiya
GitHub’dagi asl loyiha
Bu tezkor tugmalarni hozircha oʻzgartirib boʻlmaydi.
AURA bu soʻzlarni hech qachon oʻzgartirmaydi, notoʻgʻri joylashuvda terilganlarni esa ularga tuzatadi.
AURA ularni bosh harflar bilan yozadi (TTN), notoʻgʻri joylashuvda terilgan boʻlsa ham.
Bu ilovalarda AURA hech narsa qilmaydi. Toʻliq ekranli oʻyinlar avtomatik toʻxtatiladi.
Shu ilovalardan biriga oʻtganingizda, AURA joylashuvni tanlangan tilga almashtiradi.

ga Gaeilge
Cumasaithe
Ceartú uathoibríoch
Fuaim
⚠︎ Tabhair rochtain: Inrochtaineacht, Input Monitoring
Aip:
Ná oibrigh san aip seo
Cluiche — AURA ar sos
Teanga don aip seo
Gan nasc
Eisceachtaí
Ná oibrigh i (aipeanna le déanaí)
Naisc teanga
Folamh
Seol ag logáil isteach
Mo chuid focal…
Sábháil
Cealaigh
Teanga an roghchláir
Gach teanga
An Eoraip
An Chugais agus an Áise Láir
An Mheánoirthear
An Áise
Córas
⇧ faoi dhó — tiontaigh focal/roghnúchán
Tuairiscigh fadhb…
Cad a tharla agus in cén aip:
Seiceáil le haghaidh nuashonruithe…
⬆︎ B’fhéidir go bhfuil nuashonrú ar fáil — seiceáil
Tacaigh le AURA Switcher ☕
Scoir
Tá AURA Switcher {v} amuigh
Tá an leagan is déanaí agat
Cad atá nua
Nuashonraigh
Níos déanaí
Níorbh fhéidir nuashonrú go huathoibríoch. An bhfuil fonn ort an suíomh gréasáin a oscailt chun é a íoslódáil?
Tá AURA Switcher ag rith. Tá an deilbhín sa limistéar fógraí; cliceáil ^ cois an chloig chun an roghchlár a oscailt
Ceartaigh cás na litreacha
Giorrúcháin…
⌥ + ⇧ faoi dhó — athraigh cás na litreacha
Socruithe…
Ginearálta
Aicearraí
Focail
Aipeanna
Faoi
Focal
Aip
Teanga
Cuardaigh
Cuir leis
Bain
Roghnaigh aip…
Aipeanna le déanaí
Leagan
An bunthionscadal ar GitHub
Ní féidir na aicearraí seo a athrú go fóill.
Ní athraíonn AURA na focail seo choíche, agus ceartaíonn sé chucu iad siúd a clóscríobhadh sa leagan amach mícheart.
Scríobhann AURA iad i mbarrlitreacha (TTN), fiú má clóscríobhadh iad sa leagan amach mícheart.
Ní dhéanann AURA aon rud sna haipeanna seo. Cuirtear cluichí lánscáileáin ar sos go huathoibríoch.
Nuair a athraíonn tú go ceann de na haipeanna seo, athraíonn AURA an leagan amach go dtí an teanga roghnaithe.

mt Malti
Attivat
Korrezzjoni awtomatika
Ħoss
⚠︎ Agħti aċċess: Aċċessibbiltà, Input Monitoring
Applikazzjoni:
Taħdimx f’din l-applikazzjoni
Logħba — AURA fil-pawża
Lingwa għal din l-applikazzjoni
L-ebda rabta
Eċċezzjonijiet
Taħdimx fi (applikazzjonijiet reċenti)
Rabtiet tal-lingwi
Vojt
Ibda mad-dħul
Kliemi…
Salva
Ikkanċella
Lingwa tal-menu
Il-lingwi kollha
Ewropa
Il-Kawkasu u l-Asja Ċentrali
Il-Lvant Nofsani
L-Asja
Sistema
⇧ doppju — ikkonverti kelma/għażla
Irrapporta problema…
X’ġara u f’liema applikazzjoni:
Iċċekkja għal aġġornamenti…
⬆︎ Jista’ jkun hemm aġġornament — iċċekkja
Appoġġa lil AURA Switcher ☕
Ieqaf
AURA Switcher {v} ħareġ
Għandek l-aħħar verżjoni
X’hemm ġdid
Aġġorna
Aktar tard
Ma setax jiġi aġġornat awtomatikament. Niftaħ is-sit biex tniżżlu?
AURA Switcher qed jaħdem. L-ikona tinsab fiż-żona tan-notifiki; ikklikkja fuq ^ ħdejn l-arloġġ biex tiftaħ il-menu
Ikkoreġi l-ittri kapitali
Abbrevjazzjonijiet…
⌥ + ⇧ doppju — biddel il-kobor tal-ittri
Issettings…
Ġenerali
Shortcuts
Kliem
Applikazzjonijiet
Dwar
Kelma
Applikazzjoni
Lingwa
Fittex
Żid
Neħħi
Agħżel applikazzjoni…
Applikazzjonijiet reċenti
Verżjoni
Il-proġett oriġinali fuq GitHub
Dawn ix-shortcuts għadhom ma jistgħux jinbidlu.
AURA qatt ma tbiddel dan il-kliem, u tirranġa fih dak miktub bit-tqassim żbaljat.
AURA tikteb dawn b'ittri kapitali (TTN), anki jekk inkitbu bit-tqassim żbaljat.
F'dawn l-applikazzjonijiet AURA ma tagħmel xejn. Il-logħob bi skrin sħiħ jitwaqqaf awtomatikament.
Meta taqleb għal waħda minn dawn l-applikazzjonijiet, AURA tbiddel it-tqassim għal-lingwa magħżula.

cy Cymraeg
Wedi’i alluogi
Cywiro awtomatig
Sain
⚠︎ Rhowch fynediad: Hygyrchedd, Input Monitoring
Ap:
Peidio â gweithio yn yr ap hwn
Gêm — AURA wedi’i oedi
Iaith ar gyfer yr ap hwn
Dim cysylltiad
Eithriadau
Peidio â gweithio yn (apiau diweddar)
Cysylltiadau iaith
Gwag
Cychwyn wrth fewngofnodi
Fy ngeiriau…
Cadw
Diddymu
Iaith y ddewislen
Pob iaith
Ewrop
Y Cawcasws a Chanolbarth Asia
Y Dwyrain Canol
Asia
System
⇧ dwbl — trosi gair/dewisiad
Adrodd am broblem…
Beth ddigwyddodd ac ym mha ap:
Gwirio am ddiweddariadau…
⬆︎ Efallai bod diweddariad ar gael — gwiriwch
Cefnogi AURA Switcher ☕
Gadael
Mae AURA Switcher {v} allan
Mae gennych y fersiwn ddiweddaraf
Beth sy’n newydd
Diweddaru
Yn nes ymlaen
Methu diweddaru’n awtomatig. Agor y wefan i’w lawrlwytho?
Mae AURA Switcher yn rhedeg. Mae’r eicon yn yr ardal hysbysu; cliciwch ^ wrth ymyl y cloc i agor y ddewislen
Cywiro priflythrennau
Byrfoddau…
⌥ + ⇧ dwbl — newid priflythrennau
Gosodiadau…
Cyffredinol
Llwybrau byr
Geiriau
Apiau
Ynghylch
Gair
Ap
Iaith
Chwilio
Ychwanegu
Dileu
Dewis ap…
Apiau diweddar
Fersiwn
Y prosiect gwreiddiol ar GitHub
Ni ellir newid y llwybrau byr hyn eto.
Nid yw AURA byth yn newid y geiriau hyn, ac mae'n cywiro iddynt y rhai a deipiwyd yn y cynllun anghywir.
Mae AURA yn eu hysgrifennu mewn priflythrennau (TTN), hyd yn oed os cawsant eu teipio yn y cynllun anghywir.
Nid yw AURA yn gwneud dim yn yr apiau hyn. Caiff gemau sgrin lawn eu seibio'n awtomatig.
Pan fyddwch yn newid i un o'r apiau hyn, mae AURA yn newid y cynllun i'r iaith a ddewiswyd.
"""

langs = []  # (code, name, [strings])
for block in LANGS.strip().split("\n\n"):
    head, *lines = block.split("\n")
    code, name = head.split(" ", 1)
    assert len(lines) == len(KEYS), (code, len(lines))
    lines[KEYS.index("app")] += " "  # "App: " + app name
    langs.append((code, name, lines))

SWIFT_REGIONS = """/// Menu-language picker: a few likely languages on top, the rest under "All languages" by region.
/// Regions in menu order (title key → codes); a language not listed here goes to the first region.
let uiRegions: [(String, [String])] = [("regEurope", []), ("regCaucasus", ["kk", "ky", "ka", "hy", "az", "tg", "mn", "uz"]), ("regMiddleEast", ["he", "ar", "fa", "ku"]), ("regAsia", ["hi", "ko", "zh", "ja", "vi"])]
func uiRegionIndex(_ code: String) -> Int { uiRegions.firstIndex { $0.1.contains(code) } ?? 0 }
/// the languages shown on top of the picker: the current one, English, then the languages of the user's keyboard layouts
func uiTopLangs(current: String, layoutLangs: [String]) -> [String] {
    var top: [String] = []
    for c in [current, "en"] + layoutLangs where uiLangs.contains(c) && !top.contains(c) && top.count < 6 { top.append(c) }
    return top
}
"""

def esc(s): return s.replace("\\", "\\\\").replace('"', '\\"')

def put(path, begin, end, body):
    p = ROOT / path; s = p.read_text()
    s2, n = re.subn(re.escape(begin) + r".*?" + re.escape(end), lambda _: begin + "\n" + body + end, s, flags=re.S)
    assert n == 1, path
    p.write_text(s2)

B, E = "// BEGIN menu strings — generated by tools/menu_i18n.py, edit there", "// END menu strings"
swift = "let uiLangs = [" + ", ".join(f'"{c}"' for c, _, _ in langs) + "]\n"
swift += "let uiLangNames = [" + ", ".join(f'"{n}"' for _, n, _ in langs) + "]\n"
swift += SWIFT_REGIONS
swift += "let uiStrings: [String: [String]] = [ // key: one string per uiLangs\n"
for i, k in enumerate(KEYS):
    swift += f'    "{k}": [' + ", ".join(f'"{esc(l[i])}"' for _, _, l in langs) + "],\n"
swift += "]\n"
put("engine.swift", B, E, swift)

cpp = f"static const int UI_N = {len(langs)};\n"
cpp += "static const wchar_t* const UI_LANGS[UI_N] = {" + ", ".join(f'L"{c}"' for c, _, _ in langs) + "};\n"
cpp += "static const wchar_t* const UI_NAMES[UI_N] = {" + ", ".join(f'L"{n}"' for _, n, _ in langs) + "};\n"
cpp += "static const wchar_t* const UI_STR[][UI_N] = { // row: English first, then the other UI_LANGS\n"
for i, k in enumerate(KEYS):
    cpp += "    {" + ", ".join(f'L"{esc(l[i])}"' for _, _, l in langs) + "},\n"
cpp += "};\n"
put("windows/aura.cpp", B, E, cpp)
print(f"{len(langs)} languages × {len(KEYS)} strings")
