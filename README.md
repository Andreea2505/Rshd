Cuprins:
I. Descrierea problemei

1) Contextul problemei
2) Definirea problemei
3) Importanta problemei
4) Solutii posibile
5) Masurarea performantei

II. Descrierea soluției adoptate
1) Formalizarea problemei
2) Obiectivele proiectului
3) Caracteristicile prototipului
4) Cerinte generale
5) Presupuneri, constrangeri si dependente

III. Design

1) Descrierea arhitecturii software
2) Alegerea mecanismelor si a algoritmilor
3) Descrierea mecanismelor/algoritmilor folosiți
4) Particularitățile adaptării mecanismelor la problemă

IV. Implementare

1) Componentele software
2) Biblioteci software
3) Probleme tehnice
4) Limitari ale implementarii

V. Experimente

1) Arhitectura hardware/software pentru testare
2) Use Case-uri folosite pentru evaluare experimentală
3) Performanta

VI. Concluzii

I. Descrierea problemei
1)Contextul problemei
În sistemele de operare moderne, procesele rulează adesea izolate. Pentru a colabora,
acestea necesita mecanisme de comunicare (Inter-Process Communication). Un mecanism
fundamental in aceasta privinta, disponibil pe sistemele Linux, este FIFO (First-In, First-Out),
cunoscut și sub numele de named pipe. Spre deosebire de pipe-urile obișnuite, fișierele FIFO
pot fi referite (au un nume) și persista în sistemul de fișiere, permițând proceselor care nu sunt
înrudite (părinte-copil) să schimbe date într-un flux unidirecțional.
Problema comunicării între procese este fundamentală în proiectarea sistemelor de
operare moderne. Aparitia necesitatii unei soluții de tip "Remote Shell" (RSH) implementată
local, folosind mecanisme elementare precum FIFO (First-In, First-Out), este datorata nevoii
de a înțelege cum se pot decupla componentele software (la nivel local de executie) în scopuri
educaționale și arhitecturale. Importanța practică se remarca în cazurile de administrare a
sistemului unde un proces privilegiat (Master/Slave) trebuie să execute comenzi în numele
unor procese neprivilegiate sau distincte, menținându-se un control strict asupra fluxului de
date și a resurselor alocate, evitând blocarea clientului într-o așteptare activă ineficientă.

2)Definirea problemei
Problema centrală a acestui proiect este proiectarea și implementarea unui sistem local,
similar Remote Shell Daemon (RSHD), folosind mecanisme FIFO. Scopul este de a crea o
arhitectură client-server capabilă să gestioneze următoarele obiective: permiterea interacțiunii
cu clienti multiplii (sistemul trebuie să permită mai multor clienți să trimită simultan cereri către
serverul pentru a executa comenzi shell), execuția de la distanța a comenzilor (serverul trebuie
să preia aceste comenzi, să le execute într-un mediu controlat și să rezultatul sa fie returnat
clientului care a inițiat cererea) și utilizarea unui format definit pentru realizarea comunicarii
(protocolul predefinit BEGIN-REQ [client-pid: command] END-REQ).

3) Importanta problemei
Acest proiect poate demonstra cum poate fi implementat un sistem client-server
asincron folosind doar mecanisme fundamentale IPC (Inter-Process Communication) conforme
standardului UNIX, anume, în acest caz, primitive pentru transfer de date de tip FIFO (Named
Pipes). Proiectul rezolvă problema executării comenzilor într-un mediu controlat (serverul) la

cererea unor entități externe (clienții), permițând centralizarea logicii de execuție, limitarea
resurselor (prin numărul fix de slaves) și detasarea clientului de execuția propriu-zisă.

4)Solutii posibile
Există multiple mecanisme în sistemele Linux/UNIX pentru realizarea comunicării între
procese, fiecare având avantaje și dezavantaje specifice contextului: socket-uri UNIX
domain (presupun utilizarea unui canal bidirecțional de comunicare; aceasta implementare
necesită cunoștințe avansate de gestionare a conexiunilor) , memoria partajată (shared
memory) (cea mai rapidă metodă, deoarece evită copierea datelor între spațiile de memorie
ale proceselor, dar implica utilizarea unor mecanisme complexe de sincronizare, precum
semafoarele, pentru a evita coruperea datelor prin implementarea principiului de race
conditions), cozi de mesaje (message queues) (presupune o structură organizată a datelor,
dar implementarea creste complexitatea solutiei) si pipe-uri (anonime și numite/FIFO)
(pipe-urile anonime sunt utile doar pentru procese înrudite (părinte-copil), în timp ce
FIFO-urile (Named Pipes) permit comunicarea între procese, indiferent de relația lor, atâta
timp cât au acces la același sistem de fișiere).
Alegerea FIFO-urilor pentru realizarea solutiei este justificată prin simplitatea utilizarii
(se comportă ca fișiere standard). Acestea permit utilizarea comenzilor standard (cat, echo,
read) pentru manipulare și oferă, în același timp, o sincronizare implicită: citirea dintr-un FIFO
gol blochează procesul până când este scris conținutul, eliminând necesitatea unor
mecanisme de polling mai complexe (precum în cazul cozilor de mesaje).
Spre deosebire de serverele RSH/SSH clasice care utilizează socket-uri de rețea și
permit execuția comenzilor între mașini fizice distincte printr-o rețea, soluția implementată
pentru acest proiect este limitată la nivelul aceleiași mașini. RSH-ul clasic include mecanisme
de autentificare și criptare, în timp ce implementarea din cazul de fata se bazează pe
permisiunile sistemului de fișiere și pe PID-uri pentru directionarea cererilor. Avantajul soluției
propuse este simplitatea și lipsa necesității unui daemon propriu-zis care să aștepte cererile
de la porturile privilegiate, totul rulând în user-space prin scripturi Bash standard.

5) Masurarea performantei
Evaluarea soluției se concentrează pe latența sistemului și corectitudinea distribuirii
sarcinii. In aceasta privinta, se monitorizeaza timpul scurs din momentul în care Clientul scrie
în MASTER_FIFO până când primește răspunsul în FIFO-ul său propiru. Un alt indicator de
performanță este echilibrarea încărcării sarcinilor (Load Balancing), verificându-se dacă
logica Round-Robin distribuie comenzile uniform către serverele Slave, evitând cazul în care
un proces Slave nu executa nimic, iar celelalte pot fi suprasolicitate (precum se poate
intampla în cazul unei logici Least Connections).

II. Descrierea soluției
1)Formalizarea problemei
Problema poate fi formalizată sub forma unui sistem local de procesare distribuită a
fluxurilor de date.
Consideram o multime cu numar variabil de elemente C = { c1, c2,..., cn } ce reprezinta
multimea Clienților, asupra careia putem defini o funcție req a carei imagini este redata de
multimea perechilor (PID, command), fiecarui c (client din multimea C) fiindu-i atribuita
perechea dintre PID-ul propriu și comanda trimisa spre executie. O alta functie M (procesul
dispecer Master) atribuie perechilor generate de req unul dintre elementele mulțimii cu număr
fix de elemente S = {s1, s2, ..., sk}, ce reprezinta multimea proceselor Slaves, prin formula
M(req(c)) = s % n. Procesul Slave s corespunzător executa command din perechea generata
de funcția req pentru clientul c. Rezultatul execuției, este returnat direct clientului printr-un
canal dedicat, evitand dispecerul (Master) pentru a minimiza latența.

2)Obiectivele proiectului
Obiectivul principal al proiectului este crearea unui sistem de execuție a comenzilor
shell care să simuleze comportamentul unui server concurent, folosind o arhitectură orientată
pe evenimente (event-driven) la nivel de Master și procesare paralelă la nivel de Slaves. Se
dorește obținerea unei arhitecturi extensibile unde numărul de unități de execuție (slaves)
poate fi configurat dinamic prin variabila N_SLAVES, fără a modifica codului scripturilor..
Din punct de vedere didactic, un obiectiv este aprofundarea conceptelor de
sincronizare a proceselor în UNIX fără a fi utilizate biblioteci de nivel înalt, rezultand situatia in
care este necesara înțelegerea modului în care kernel-ul gestionează apelurile de sistem
blocante (read/write pe FIFO).
Un alt obiectiv specific este reprezentat de gestionarea corectă și implementarea
adecvată a unei logici pentru garbage collection. Deoarece FIFO-urile sunt persistente,
obiectivul este ca scripturile să nu lase fișiere abandonate în /tmp, prevenind "poluarea"
sistemului de fișiere în cazul opririi (fie neprevăzute sau nu).

3)Caracteristicile prototipului
Prototipul este constituit din trei scripturi și un fișier de configurare. Caracteristică
definitorie este modularitatea arhitecturii implementate: procesul Master se ocupă exclusiv de
distribuirea/rutarea sarcinilor, procesul Slave de execuție, iar Clientul de constituirea unei
interfețe pentru utilizator.
Scopul proiectului este de a îndeplini un use-case minimal în care utilizatorii , prin
Clienti, pot rula comenzi shell prin intermediul serverului, primind același output exact ca și
cum ar fi fost rulata local comanda, prelucrarea și execuția comenzilor având loc în alte
procese separate.

4)Cerinte generale
Din punct de vedere funcțional, sistemul trebuie să proceseze corect formatul
BEGIN-REQ [client-pid: command] END-REQ și să ignore cererile care nu il respectă. Cerințele
de utilizare impun ca scripturile să curețe automat resursele (fișierele FIFO) la închidere, lucru
implementat prin variația funcției cleanup și a mecanismul trap din scripturile client și master.
Din punct de vedere tehnic, sistemul trebuie să permită rularea concurentă a mai multor clienți
fără a fi corupte datele și să interacționeze fara erori cu utilitarele standard din Linux. Drept
urmare, platforma pentru dezvoltarea si utilizarea proiectului poate fi orice distribuție Linux.
Rularea proiectului nu necesită permisiuni de root, atâta timp cât utilizatorul are drept de
scriere în directoarele temporare.
Cerințele de sistem sunt minimale. Fiecare proces bash consumă aproximativ 1-4 MB
RAM. Pentru un sistem cu 3 Slaves + 1 Master + 3 Clients, necesarul de memorie este în jur de
50 MB, permițând execuția și pe hardware foarte vechi sau embedded. Puterea de calcul este
neglijabilă pentru logica de rutare, iar performanța depinde exclusiv de comenzile executate
de clienți.
Nu sunt necesare biblioteci externe. Prototipul se bazează exclusiv pe coreutils
(pachetul standard GNU care contine functii precum ls, mv, rm, mkfifo, sed, grep s.a).

5)Presupuneri, constrângeri și dependențe
Se presupune că utilizatorul are permisiuni de scriere în directorul /tmp și că nu există
alte procese care să scrie interfereze cu fișierele FIFO definite sau cu fișierele ce conțin
scripturile.
O constrângere semnificativă a implementării prototipului este securitatea: serverul
slave folosește eval pentru a executa comenzile, astfel ca un utilizator rău intenționat ar putea

folosi comenzi considerate periculoase ce pot provoca daune sistemului, deși este inclusă o
verificare simpla pentru comenzile rm și mv.
Dependența principală este fișierul fifo_rshd.config, a cărui lipsă oprește execuția
tuturor componentelor. In plus, comenzile sed și mkfifo trebuie să fie prezente în $PATH.

6) Plan de evaluare
Evaluarea se poate realiza din mai multe perspective.
Testarea funcțională a prototipului se poate face prin trimiterea unor comenzi simple
(ls, date, whoami) si verificarea outputlui, care va fi identic cu acela rezultat din execuția
locală a comenzii, și prin încercarea de a trimite comenzi invalide sau inexistente, ce va rezulta
într-un mesaj de eroare (stderr).
Testarea capacității prototipului poate fi realizata prin lansarea simultană a unui număr
variabil de clienți (10, 20, etc) și monitorizarea log-urilor sau a output-ului standard (stdout).
Metrică principală de evaluare este rata de succes a comenzilor (câte dintre cereri primesc
output-ul corespunzător) și timpul de "round-trip". De asemenea, se va putea verifica că
fișierele FIFO temporare sunt șterse adecvat după finalizarea rulării.

III. Design
1)Descrierea arhitecturii software
Sistemul utilizează o arhitectură de tip Master-Slave(Load-Balancer Dispatcher)cu
comunicare prin cozi implementate prin FIFO.
Clientul este un proces temporar care creează canalul de răspuns, trimite cererea și
se blochează în așteptarea răspunsului. Masterul este un proces similar cu unul daemon
(rulează continuu) și acționează ca un Load Balancer. Acesta nu se ocupa cu executia
propriu-zisa, ci doar directioneaza cererile și menține logica Round-Robin. Sclavii sunt
procese persistente, create la inițializarea Masterului. Fiecare Slave are propria coadă de
intrare. Aceștia execută comanda folosind eval și scriu direct în canalul de răspuns al
clientului.
Mecanismul de comunicare este asincron între Client și Master, dar sincron între Client
și Slave (Clientul trebuie sa astepte Slave-ul).

2)Alegerea mecanismelor si a algoritmilor
Am utilizat FIFO-uri pentru a reduce complexitatea codului. Un socket server în Bash ar
necesita utilitare non-standard (precum netcat) sau operatiuni complexe cu fișiere în /dev/tcp.
FIFO-urile sunt native și atomice pentru scrieri mici (sub PIPE_BUF, de regulă, 4KB), ceea ce
simplifică prevenirea coruperii datelor când mai mulți clienți scriu simultan în MASTER_FIFO.
A fost utilizata logica Round-Robin (rr_counter % N_SLAVES) pentru distribuirea
sarcinilor, deoarece este cel mai simplu algoritm care garantează o distribuție echitabilă fără a
necesita menținerea unei stări complexe despre gradul încărcarii curente a fiecărui Slave.
Alternativ, ar fi fost folosită o coadă unică partajată de slave-uri, dar aceasta ar fi introdus
race conditions la citire, pentru a fi evitată citirea inadecvata sau fragmentata a protocoalelor
de comunicare. Round-Robin garantează, cu un cost computațional minim (O(1)), că niciun
mesaj nu este pierdut sau duplicat.

3)Descrierea mecanismelor/algoritmilor folosiți
Mecanismul central este mkfifo, care creează pipe-urile denumite. Algoritmul de
parsare din Master folosește utilitarul sed pentru a extrage PID-ul și comanda folosind expresii
regulate. Este folosit sed (Stream Editor) cu expresii regulate extinse (-E). Regex-ul
“s/.*\[([0-9]+):.*/\1/” extrage PID-ul, bazându-se pe delimitatorii “[“ și “:”, iar regex-ul
“s/^BEGIN-REQ \[[0-9]+: (.*)\] END-REQ$/\1/“ extrage comanda, bazându-se pe structura
fixă a protocolului. Execuția efectivă în procesele Slave se bazează pe eval, care permite
interpretarea dinamică a șirului de caractere primit ca o comandă shell validă. Fluxul standard
de ieșire (stdout) și eroare (stderr) rezultat prin executarea comenzii este redirectionat către
pipe-ul de răspuns.

4)Particularitățile adaptării mecanismelor la problemă
Particularitatea distinctivă față de un server web clasic este modul în care este
gestionat canalul de răspuns. În loc că procesul Master să intermedieze răspunsul, procesul
Slave aferent primește calea către FIFO-ul de răspuns (REPLY_FIFO) ca parte a mesajului
intern trimis de Master. De asemenea, constrângerea de a folosi FIFO-uri impune ca cititorul
(Slave-ul) să redeschidă pipe-ul pentru a evita primirea semnalului EOF prematur.

IV. Implementare
1)Componentele software
Proiectul este constituit logic și fizic din 4 componente.
Fișierul de Configurare (fifo_rshd.config) acționează la fel ca un header file în
C/C++. Acesta centralizează căile (/tmp/rshd_master_fifo) pentru a asigura consistența între
scripturi. Orice modificare a numărului de sclavi sau a directoarelor se realizeaza într-un
singur loc.
Clientul (client.sh) este interfața prin care utilizatorul utilizeaza serverul. Aceasta
componenta are ca rol si gestionarea parcursului cererii utilizatorului: generarea PID, crearea
canalului de răspuns, trimiterea cererii, afișarea rezultatului, curatarea fișierelor reziduale.
Funcției cleanup si aplicarea ei prin mecanismului trap asigură ștergerea fișierului FIFO de
răspuns (/tmp/server-reply-$CLIENT_PID) la terminarea execuției sau în caz de întrerupere.
Identificatorul unic de proces ($$) este utilizat pentru a crea canalul de comunicare privat,
evitându-se posibile interferente cu alti clienti concurenti. Comunicarea dintre Client si Master
se realizeaza printr-un format strict ( BEGIN-REQ [$CLIENT_PID: $COMMAND] END-REQ ).
După trimiterea cererii, Clientul intră în starea de așteptare, citind din propriul FIFO. Odată ce
rezultatul este primit, acesta este afișat la ieșirea standard, iar executia se încheie prin
ștergerea resurselor temporare create.
Masterul (master.sh) este componenta care se ocupă cu initializarea mediului de
lucru (crearea directoarelor), gestionarea proceselor copil inițiate (procesele Slave) și logica
de directionare a cererilor. Inițializarea implică crearea fișierului MASTER_FIFO și lansarea în
background a unui număr de instanțe slave.sh definit de variabila N_SLAVES, fiecare avand un
ID distinct. În bucla infinită de procesare, masterul citește cererile primite secvențial și validează
formatul acestora. Folosind sed, se extrage PID-ul clientului și comanda propriu-zisă.
Distribuirea sarcinilor se realizează printr-un algoritm de tip Round Robin. Odată determinat
sclavul responsabil, masterul construiește calea către FIFO-ul acestuia și trimite catre acesta o
linie compusă din calea de răspuns către client și comanda ce trebuie executată,
incrementându-se, apoi, contorul pentru următoarea cerere. La oprirea master.sh, se vor
termina forțat toate procesele copil și vor fi șterse directoarele temporare prin folosirea unei alte
functii cleanup ce este aplicata printr-un mecanism trap (la fel ca in cazul din client.sh).
Sclavul (slave.sh) este componenta ce se ocupă de execuția comenzilor trimise de
utilizator. La inițializare, fiecare Slave își creează propriul canal de comunicare într-un director
dedicat, unde așteapta instrucțiuni de la procesul Master. In bucla principală se citește dintr-o
singură linie atât calea către FIFO-ul clientului, cât și comanda de executat, asa cum au fost
trimise de Master. Inainte de a executa comanda prin eval, este utilizat un mecanism minim de
protectie împotriva unor comenzi cu comportament ce poate altera conținutul sistemului de

fișiere (rm , mv), astfel ca execuția acestora poate fi prevenita și se returnează un mesaj de
eroare in acest caz ("Error: Forbidden"). În cazul comenzilor permise, sclavul utilizează eval
pentru a rula instrucțiunea, redirectionand atât ieșirea standard (stdout), cât și erorile (stderr)
spre canalul de răspuns al clientului (> "$REPLY_FIFO" 2>&1), garantandu-se că utilizatorul
primește un output fidel cu cel al utilizarii locale ale comenzii dorite.

2) Biblioteci software
Au fost utilizate exclusiv utilitarele standard GNU Coreutils (ls, cat, rm, mkdir, mkfifo,
seq) și funcționalitățile native ale Bash (trap, source, read, expansiunea variabilelor). În acest
fel este asigurata si portabilitatea pe orice sistem Linux modern fără instalarea de software
suplimentar.

3)Probleme tehnice
O problemă tehnică poate fi gestionarea întreruperii proceselor. Dacă un utilizator
oprește forțat clientul, FIFO-ul de răspuns ar putea rămâne pe disc. Soluția implementată a
fost utilizarea comenzii trap cleanup SIGINT SIGTERM EXIT , care garantează execuția
funcției de curățare indiferent de modul în care scriptul se termină.
O alta problema identificata este cea a curățării proceselor copil, anume când
Master-ul este oprit (Ctrl+C), sclavii rămân “orfani”, rulând în background. Soluție adoptată a
fost utilizarea “pkill -P $$” în funcția cleanup din scriptul Master. Aceasta trimite semnalul de
terminare tuturor proceselor care au ca părinte procesul Master.
Problema protocolului Intern de comunicare dintre Master și Slave, mai exact trimiterea
comenzii către Slave putea fi compromisa dacă comanda conținea caractere speciale, a fost
rezolvata prin trimiterea numelui FIFO de răspuns urmat de comandă, acestea fiind separate
prin spațiu, bazându-ne pe faptul că prin definirea cailor de fișiere in acest caz acestea nu pot
contine spații.
De asemenea, folosirea eval pentru comenzi neverificate în avans poate fi periculoasa.
S-a implementat o filtrare rudimentară pentru rm și mv, dar un utilizator poate ocoli acest filtru
prin ascunderea acestor comenzi în alte scripturi trimise spre execuție.

4)Limitari ale implementarii
O limitare a prototipului este scalabilitatea I/O. Deoarece se bazează pe fișiere fizice în
/tmp, performanța scade dacă discul este lent sau încărcat. De asemenea, protocolul este

sensibil la caractere speciale în comenzi; dacă o comandă conține șirul "END-REQ", parsarea
în Master va eșua.
O alta limitare este lipsa unor mecanisme de timeou. Dacă un Slave se blochează într-o
comandă, el devine indisponibil, dar Master-ul va continua să îi trimită cereri conform
algoritmului Round-Robin, ducând la pierderea acelor cereri. In alt caz, dacă un Slave eșuează
(segfault), Master-ul nu detectează acest lucru și va continua să trimită cereri către un pipe
care nu mai are cititor (Broken Pipe), ajungandu-se iarăși la o situație în care cererile sunt
pierdute.

V. Experimente

1) Arhitectura hardware/software pentru testare
Pentru testare a fost utilizata o arhitectură software compusă dintr-un singur nod,
anume o mașină virtuală Linux (Ubuntu 24.04). Arhitectura de test implică rularea unui proces
Master, care generează N_SLAVES procese copil (mai exact 3, conform configurației). Datele
experimentale sunt șiruri de caractere text reprezentând comenzi shell standard. Dimensiunea
problemei este scalabilă prin modificarea parametrului N_SLAVES și lansarea unui număr
arbitrar de instanțe client.sh.

2) Use-case-uri folosite pentru evaluare experimentală
Testul de secvențialitate: a fost rulat scriptul client.sh de 3 ori consecutiv cu comanda
echo "testare distribuire". S-a verificat output-ul Master-ului pentru a confirma că Slave 1,
Slave 2 și Slave 3 au preluat comenzile în această ordine exactă (Round Robin).
Testul de interdicție: a fost încercata comanda “ ./client.sh rm -rf /tmp/test “. S-a
validat că Slave-ul a interceptat comanda și a returnat "Error: Forbidden", demonstrandu-se
funcționalitatea de filtrare simplă.
Testul de solicitare (load): au fost lansați 4 clienți simultan. S-a observat că cererile
primilor 3 au fost preluate de cei 3 sclavi, iar a patra cerere a rămas în așteptare până când
unul dintre sclavi (primul, conform Round-Robin) s-a eliberat.

3)Performanta
Sistemul demonstrează un timp de răspuns minim (mai putin de o secunda) pentru
comenzi ușoare, deoarece overhead-ul (costul de administrare) este doar cel al creării
proceselor și scrierii în fișiere.
Gradul de fragmentare al memoriei este irelevant, deoarece procesele shell sunt
temporare sau utilizează memoria eficient. Totuși, "throughput-ul" (debitul de date) este limitat
de viteza de scriere pe disc (FIFO-urile sunt fișiere) și de viteza interpretorului Bash.
La un volum ridicat de cereri într-un interval de timp scurt, nu s-au pierdut date, fapt ce
arata că buffer-ul kernel-ului pentru FIFO este suficient pentru cresterea rapida de trafic text
intr-un interval de timp scurt.

VI. Concluzii
Aspecte importante remarcate
Prin acest proiect, se evidențiază complexitatea sincronizării proceselor fără primitive
avansate (mutex-uri, semafoare), bazându-se doar pe proprietățile blocante ale fișierelor FIFO.
Am înțeles practic cum procesele pot colabora folosind named pipes (FIFO) pentru a
schimba date fără a fi înrudite.
Un aspect de reținut este importanța gestionării corecte a semnalelor (trap) pentru a
preveni "procesele zombie" sau fișierele "trash" rămase în urma unei opriri forțate.
Am implementat o strategie de tip Round-Robin pentru a împărți munca între mai multe
servere „slave”, observand astfel o metoda prin care niciun proces nu este suprasolicitat în timp
ce altele sunt inactive. Totodata, am analizat și eficiența modelului producător-consumator
decuplat, care permite sistemului să rămână receptiv chiar și sub sarcină.
Nu in ultimul rand, a fost remarcat și potențialul redirecționărilor în shell, care permit
construirea unor arhitecturi complexe de comunicare cu o sintaxă relativ simplă.
