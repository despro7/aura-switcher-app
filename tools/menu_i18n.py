#!/usr/bin/env python3
"""Menu translations for both apps. Edit here, then run: python3 tools/menu_i18n.py
Rewrites the generated blocks in engine.swift and windows/aura.cpp (between the BEGIN/END markers).
Russian system → Ukrainian menu (no Russian translation on purpose)."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
KEYS = ["enabled", "auto", "sound", "access", "app", "exclude", "game", "appLang", "noBinding", "exclusions", "recent",
        "bindings", "empty", "login", "words", "wordsTitle", "wordsInfo", "save", "cancel", "uiLang", "allLangs", "regEurope", "regCaucasus", "regMiddleEast", "regAsia", "system", "hint",
        "report", "reportBody", "update", "updateDue", "donate", "quit", "updNew", "updLatest", "updNotes", "updNow", "updLater", "updFail"]
# code, native name, then one line per key (in KEYS order)
LANGS = """
en English
Enabled
Auto-correction
Sound
⚠︎ Grant access: Accessibility
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
AURA Switcher — my words
AURA Switcher treats these words as correct: it never changes them, and fixes them when typed in the wrong layout. Separate them with commas.
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

uk Українська
Увімкнено
Автовиправлення
Звук
⚠︎ Надайте доступ: Універсальний доступ
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
AURA Switcher — мої слова
Ці слова AURA Switcher вважає правильними: не змінює їх, а набрані не в тій розкладці — виправляє на них. Через кому.
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

pl Polski
Włączone
Autokorekta
Dźwięk
⚠︎ Nadaj dostęp: Dostępność
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
AURA Switcher — moje słowa
AURA Switcher uznaje te słowa za poprawne: nigdy ich nie zmienia, a wpisane w złym układzie poprawia na nie. Oddziel je przecinkami.
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

de Deutsch
Aktiviert
Autokorrektur
Ton
⚠︎ Zugriff erlauben: Bedienungshilfen
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
AURA Switcher — meine Wörter
AURA Switcher hält diese Wörter für richtig: ändert sie nie und korrigiert sie, wenn sie im falschen Layout getippt wurden. Durch Kommas trennen.
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

es Español
Activado
Autocorrección
Sonido
⚠︎ Conceder acceso: Accesibilidad
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
AURA Switcher — mis palabras
AURA Switcher considera correctas estas palabras: nunca las cambia y las corrige si se escriben con la distribución equivocada. Sepáralas con comas.
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

fr Français
Activé
Correction automatique
Son
⚠︎ Autoriser l'accès : Accessibilité
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
AURA Switcher — mes mots
AURA Switcher considère ces mots comme corrects : il ne les modifie jamais et les corrige s'ils sont tapés avec la mauvaise disposition. Séparez-les par des virgules.
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

it Italiano
Attivo
Correzione automatica
Suono
⚠︎ Concedi l’accesso: Accessibilità
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
AURA Switcher — le mie parole
AURA Switcher considera corrette queste parole: non le modifica mai e le corregge se le digiti con il layout sbagliato. Separale con una virgola.
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

pt Português
Ativado
Correção automática
Som
⚠︎ Conceder acesso: Acessibilidade
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
AURA Switcher — as minhas palavras
O AURA Switcher considera estas palavras corretas: nunca as altera e corrige-as se forem digitadas no layout errado. Separe-as com vírgulas.
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

tr Türkçe
Etkin
Otomatik düzeltme
Ses
⚠︎ Erişim izni verin: Erişilebilirlik
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
AURA Switcher — kelimelerim
AURA Switcher bu kelimeleri doğru kabul eder: asla değiştirmez, yanlış düzende yazılırsa onlara düzeltir. Virgülle ayırın.
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

nl Nederlands
Ingeschakeld
Autocorrectie
Geluid
⚠︎ Geef toegang: Toegankelijkheid
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
AURA Switcher — mijn woorden
AURA Switcher beschouwt deze woorden als juist: verandert ze nooit en verbetert ze als ze in de verkeerde indeling zijn getypt. Scheid ze met komma's.
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

cs Čeština
Zapnuto
Automatické opravy
Zvuk
⚠︎ Udělte přístup: Zpřístupnění
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
AURA Switcher — moje slova
AURA Switcher považuje tato slova za správná: nikdy je nemění a opraví je, když jsou napsána ve špatném rozložení. Oddělte je čárkami.
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

sv Svenska
Aktiverad
Autokorrigering
Ljud
⚠︎ Ge åtkomst: Hjälpmedel
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
AURA Switcher — mina ord
AURA Switcher ser dessa ord som rätt: ändrar dem aldrig och rättar dem om de skrivs med fel layout. Separera med kommatecken.
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

fi Suomi
Käytössä
Automaattinen korjaus
Ääni
⚠︎ Anna käyttöoikeus: Käyttöapu
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
AURA Switcher — omat sanat
AURA Switcher pitää näitä sanoja oikeina: ei koskaan muuta niitä ja korjaa ne, jos ne on kirjoitettu väärällä asettelulla. Erota pilkuilla.
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

ro Română
Activat
Corectare automată
Sunet
⚠︎ Acordați acces: Accesibilitate
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
AURA Switcher — cuvintele mele
AURA Switcher consideră aceste cuvinte corecte: nu le schimbă niciodată și le corectează dacă sunt tastate în aranjamentul greșit. Separați-le prin virgulă.
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

hu Magyar
Bekapcsolva
Automatikus javítás
Hang
⚠︎ Hozzáférés megadása: Kisegítő lehetőségek
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
AURA Switcher — saját szavak
Az AURA Switcher ezeket a szavakat helyesnek tekinti: soha nem módosítja őket, és kijavítja, ha rossz kiosztással gépelték. Vesszővel válassza el.
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

el Ελληνικά
Ενεργό
Αυτόματη διόρθωση
Ήχος
⚠︎ Δώστε πρόσβαση: Προσβασιμότητα
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
AURA Switcher — οι λέξεις μου
Το AURA Switcher θεωρεί σωστές αυτές τις λέξεις: δεν τις αλλάζει ποτέ και τις διορθώνει όταν πληκτρολογηθούν με λάθος διάταξη. Χωρίστε τις με κόμμα.
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

bg Български
Включено
Автокорекция
Звук
⚠︎ Дайте достъп: Достъпност
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
AURA Switcher — моите думи
AURA Switcher смята тези думи за правилни: никога не ги променя и ги поправя, ако са написани с грешната подредба. Разделете ги със запетая.
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

he עברית
מופעל
תיקון אוטומטי
צליל
⚠︎ תנו גישה: נגישות
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
AURA Switcher — המילים שלי
AURA Switcher מתייחס למילים אלה כנכונות: לעולם לא משנה אותן, ומתקן אליהן כשהן מוקלדות בפריסה הלא נכונה. הפרידו בפסיקים.
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

ar العربية
مفعّل
التصحيح التلقائي
الصوت
⚠︎ امنح الوصول: تسهيلات الاستخدام
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
AURA Switcher — كلماتي
يعدّ AURA Switcher هذه الكلمات صحيحة: لا يغيّرها أبدًا، ويصحّحها إليها إذا كُتبت بالتخطيط الخطأ. افصل بينها بفواصل.
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

hi हिन्दी
चालू
स्वतः सुधार
ध्वनि
⚠︎ अनुमति दें: सुलभता
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
AURA Switcher — मेरे शब्द
AURA Switcher इन शब्दों को सही मानता है: इन्हें कभी नहीं बदलता, और गलत लेआउट में टाइप होने पर इन्हीं में सुधार देता है। अल्पविराम से अलग करें।
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

ko 한국어
켜기
자동 수정
소리
⚠︎ 접근 권한 허용: 손쉬운 사용
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
AURA Switcher — 내 단어
AURA Switcher는 이 단어들을 올바른 단어로 봅니다. 절대 바꾸지 않고, 잘못된 자판으로 입력되면 이 단어로 고칩니다. 쉼표로 구분하세요.
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

be Беларуская
Уключана
Аўтавыпраўленне
Гук
⚠︎ Дайце доступ: Спецыяльныя магчымасці
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
AURA Switcher — мае словы
AURA Switcher лічыць гэтыя словы правільнымі: не мяняе іх, а набраныя ў няправільнай раскладцы — выпраўляе на іх. Праз коску.
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

kk Қазақша
Қосулы
Автотүзету
Дыбыс
⚠︎ Рұқсат беріңіз: Арнайы мүмкіндіктер
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
AURA Switcher — менің сөздерім
AURA Switcher бұл сөздерді дұрыс деп санайды: оларды өзгертпейді, ал қате пернетақта орналасуымен терілсе, осыларға түзетеді. Үтірмен бөліңіз.
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

ky Кыргызча
Күйгүзүлгөн
Авто оңдоо
Үн
⚠︎ Мүмкүнчүлүк бериңиз: Атайын мүмкүнчүлүктөр
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
AURA Switcher — менин сөздөрүм
AURA Switcher бул сөздөрдү туура деп эсептейт: аларды өзгөртпөйт, ал эми клавиатуранын туура эмес жайгашуусунда терилсе, ушуларга оңдойт. Үтүр менен бөлүңүз.
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

ka ქართული
ჩართულია
ავტოშესწორება
ხმა
⚠︎ მიეცით წვდომა: მისაწვდომობა
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
AURA Switcher — ჩემი სიტყვები
AURA Switcher ამ სიტყვებს სწორად მიიჩნევს: არ ცვლის მათ, ხოლო არასწორი განლაგებით აკრეფილს ამათ ასწორებს. გამოყავით მძიმეებით.
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

hy Հայերեն
Միացված է
Ինքնաուղղում
Ձայն
⚠︎ Տվեք թույլտվություն՝ Հասանելիություն
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
AURA Switcher — իմ բառերը
AURA Switcher-ն այս բառերը ճիշտ է համարում՝ չի փոխում դրանք, իսկ սխալ դասավորությամբ տպվածները ուղղում է հենց այսպես։ Բաժանեք ստորակետերով։
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

az Azərbaycan
Aktivdir
Avtomatik düzəliş
Səs
⚠︎ İcazə verin: Əlçatımlılıq
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
AURA Switcher — mənim sözlərim
AURA Switcher bu sözləri düzgün sayır: onları dəyişmir, səhv düzülüşdə yığılanda isə bunlara düzəldir. Vergüllə ayırın.
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

sr Српски
Укључено
Аутокорекција
Звук
⚠︎ Дозволите приступ: Приступачност
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
AURA Switcher — моје речи
AURA Switcher сматра ове речи исправним: не мења их, а када су откуцане у погрешном распореду — исправља их на ове. Одвојите зарезима.
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

mk Македонски
Вклучено
Автокорекција
Звук
⚠︎ Дозволете пристап: Пристапност
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
AURA Switcher — моите зборови
AURA Switcher ги смета овие зборови за точни: не ги менува, а кога се напишани во погрешен распоред — ги исправа на нив. Одвојте ги со запирки.
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

sk Slovenčina
Zapnuté
Automatické opravy
Zvuk
⚠︎ Povoľte prístup: Zjednodušenie ovládania
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
AURA Switcher — moje slová
AURA Switcher považuje tieto slová za správne: nikdy ich nemení a opravuje ich, keď sú napísané v nesprávnom rozložení. Oddeľte ich čiarkami.
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

hr Hrvatski
Uključeno
Automatski ispravak
Zvuk
⚠︎ Dopustite pristup: Pristupačnost
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
AURA Switcher — moje riječi
AURA Switcher ove riječi smatra ispravnima: nikad ih ne mijenja, a ispravlja ih kad su utipkane u pogrešnom rasporedu. Odvojite ih zarezima.
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

sl Slovenščina
Vklopljeno
Samodejni popravki
Zvok
⚠︎ Dovolite dostop: Dostopnost
Aplikacija:
V tej aplikaciji ne delaj
Igra — AURA zaustavljena
Jezik za to aplikacijo
Brez povezave
Izjeme
Ne delaj v (nedavne aplikacije)
Povezave jezikov
Prazno
Zaženi ob prijavi
Moje besede…
AURA Switcher — moje besede
AURA Switcher te besede šteje za pravilne: nikoli jih ne spremeni, popravi pa jih, če so natipkane v napačni razporeditvi. Ločite jih z vejicami.
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
Preveri posodobitve…
⬆︎ Morda je izšla posodobitev — preveri
Podpri AURA Switcher ☕
Končaj
Izšel je AURA Switcher {v}
Imate najnovejšo različico
Kaj je novega
Posodobi
Pozneje
Samodejna posodobitev ni uspela. Odprem spletno mesto za prenos?

lt Lietuvių
Įjungta
Automatinis taisymas
Garsas
⚠︎ Suteikite prieigą: Pritaikymas neįgaliesiems
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
AURA Switcher — mano žodžiai
AURA Switcher laiko šiuos žodžius teisingais: niekada jų nekeičia, o surinktus netinkamu išdėstymu — pataiso į juos. Atskirkite kableliais.
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

lv Latviešu
Ieslēgts
Automātiskā labošana
Skaņa
⚠︎ Atļaujiet piekļuvi: Pieejamība
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
AURA Switcher — mani vārdi
AURA Switcher uzskata šos vārdus par pareiziem: nekad tos nemaina un labo uz tiem, ja tie ievadīti nepareizā izkārtojumā. Atdaliet ar komatiem.
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

et Eesti
Sees
Automaatne parandus
Heli
⚠︎ Andke juurdepääs: Juurdepääsetavus
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
AURA Switcher — minu sõnad
AURA Switcher peab neid sõnu õigeks: ei muuda neid kunagi ja parandab nendeks, kui need on sisestatud vales paigutuses. Eralda komadega.
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
let uiRegions: [(String, [String])] = [("regEurope", []), ("regCaucasus", ["kk", "ky", "ka", "hy", "az"]), ("regMiddleEast", ["he", "ar", "fa", "ku"]), ("regAsia", ["hi", "ko", "zh", "ja"])]
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
