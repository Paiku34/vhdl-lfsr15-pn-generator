# 🔁 PNG — Pseudo-random Number Generator (LFSR 15-bit)

> **Progetto universitario** — Implementazione VHDL di un generatore di sequenze pseudo-casuali (PN Code) basato su un registro a scorrimento con retroazione lineare (**LFSR**) a 15 stadi.

<div align="center">

![VHDL](https://img.shields.io/badge/Language-VHDL-blue?style=for-the-badge)
![ModelSim](https://img.shields.io/badge/Simulation-ModelSim-green?style=for-the-badge)
![Vivado](https://img.shields.io/badge/Synthesis-Vivado%202022.2-orange?style=for-the-badge)
![Device](https://img.shields.io/badge/Target-Zynq--7010-red?style=for-the-badge)

</div>

---

## 📑 Indice

1. [Teoria — LFSR e sequenze PN](#-teoria--lfsr-e-sequenze-pn)
2. [Architettura del progetto](#-architettura-del-progetto)
3. [Struttura dei file](#-struttura-dei-file)
4. [Simulazione con ModelSim](#-simulazione-con-modelsim)
5. [Sintesi con Vivado](#-sintesi-con-vivado)
6. [Risultati di utilizzo FPGA](#-risultati-di-utilizzo-fpga)
7. [Come eseguire il progetto](#-come-eseguire-il-progetto)
8. [Riferimenti](#-riferimenti)

---

## 📐 Teoria — LFSR e sequenze PN

Un **Linear Feedback Shift Register (LFSR)** è un registro a scorrimento in cui il bit di ingresso è calcolato come funzione lineare (XOR) di alcuni bit del registro. Se il polinomio di retroazione è *primitivo*, l'LFSR genera una **sequenza di lunghezza massima (m-sequence)** di lunghezza:

$$L = 2^N - 1$$

dove $N$ è il numero di stadi del registro.

### Polinomio primitivo utilizzato

Per $N = 15$ stadi, il polinomio caratteristico implementato è:

$$f(x) = x^{15} \oplus x^{13} \oplus x^{9} \oplus x^{8} \oplus x^{7} \oplus x^{5} \oplus 1$$

I tap di retroazione sono quindi ai bit **Q15, Q13, Q9, Q8, Q7, Q5**, che garantiscono una lunghezza massima di:

$$L_{max} = 2^{15} - 1 = \mathbf{32767 \text{ bit}}$$

### Riferimento bibliografico

<div align="center">

![Riferimento Molinari](screenshots/Molinari-sequenze_pseudo-casuali-pages.jpg)

*Molinari — Sequenze pseudo-casuali*

</div>

---

## 🏗️ Architettura del progetto

Il generatore è implementato con un'architettura **strutturale** in VHDL. I tre componenti principali sono:

### Componenti

| Componente | File | Descrizione |
|---|---|---|
| `PNG` | `src/PNG.vhd` | Top-level: concatena 15 MUX + 15 D-FF + rete XOR |
| `D_flip_flop` | `src/D_flip_flop.vhd` | D Flip-Flop sincrono con reset asincrono attivo basso |
| `Mux` | `src/Mux.vhd` | Multiplexer 2-a-1, seleziona tra feedback e seed iniziale |

### Schema funzionale

```
         init ──────────────────────────────────────────────────┐
                                                                │ sel
IR[1..15] ──────────────────────────────────────────────────   │
                                                           │    │
     ┌─────┐   ┌────┐   ┌─────┐   ┌────┐         ┌─────┐ │  ┌─────┐
 ──▶│ MUX │──▶│ FF │──▶│ MUX │──▶│ FF │── ··· ──│ MUX │─┘  │     │
     └─────┘   └────┘   └─────┘   └────┘         └─────┘    │ XOR │──▶ feedback
       Q1        Q2       Q3        ...              Q15      │ net │
                                                              └─────┘
                                                           (tap: 15,13,9,8,7,5)
```

### Segnali principali

| Segnale | Direzione | Descrizione |
|---|---|---|
| `clk` | Input | Clock di sistema (10 ns → 100 MHz) |
| `reset` | Input | Reset asincrono, attivo basso — azzera tutti i FF |
| `init` | Input | `'1'` = caricamento seed IR; `'0'` = modalità generazione |
| `IR[1..N]` | Input | Seed iniziale (Initial Register), vettore a N bit |
| `PN_code[1..N]` | Output | Sequenza PN generata |

### Rete XOR di retroazione

La retroazione è implementata come cascata di XOR:

```
outXor(5) = Q15 ⊕ Q13 ⊕ Q9 ⊕ Q8 ⊕ Q7 ⊕ Q5
         └──────────────────────────────────▶ ingresso di FF1 (quando init = '0')
```

---

## 📁 Struttura dei file

```
Project_PNG_github/
│
├── src/                        # Sorgenti VHDL
│   ├── PNG.vhd                 # Top-level: LFSR 15-bit strutturale
│   ├── D_flip_flop.vhd         # D Flip-Flop (reset asincrono)
│   └── Mux.vhd                 # Multiplexer 2-a-1
│
├── tb/
│   └── PNG_tb.vhd              # Testbench (66000 cicli di clock)
│
├── modelsim/
│   └── PNG.mpf                 # Progetto ModelSim
│
├── Vivado/
│   └── project_PNG/
│       ├── project_PNG.xpr     # Progetto Vivado 2022.2
│       └── project_PNG.srcs/
│           └── constrs_1/new/
│               └── PNG_constraints.xdc   # Vincoli di timing (100 MHz)
│
├── screenshots/                # Immagini di simulazione e sintesi
├── PN_report.pdf               # Relazione completa del progetto
└── README.md
```

---

## 🧪 Simulazione con ModelSim

### Procedura di test (testbench)

Il testbench `PNG_tb.vhd` esegue i seguenti passi:

| Ciclo di clock | Evento |
|---|---|
| 0–2 | `reset = '0'` → tutti i FF azzerati |
| 3 | `reset = '1'` → FF abilitati |
| 3–9 | `init = '1'` → caricamento seed `IR = "000000000000001"` |
| 10 | `init = '0'` → avvio generazione sequenza PN |
| 33000 | Fine simulazione (> 32767 = un periodo completo) |

Il seed scelto è `000000000000001` (Q15=1, tutti gli altri = 0), che garantisce la sequenza di lunghezza massima $2^{15} - 1 = 32767$ bit.

### Waveform — Avvio e caricamento seed

<div align="center">

![Simulazione 1](screenshots/Immagine%202025-01-25%20104919.png)

*Vista generale della simulazione: segnali di controllo e PN_code*

</div>

<div align="center">

![Simulazione 2](screenshots/Immagine%202025-01-25%20105051.png)

*Dettaglio della fase di reset e caricamento del seed (init = '1')*

</div>

### Waveform — Generazione sequenza PN

<div align="center">

![Simulazione 3](screenshots/Immagine%202025-01-25%20105234.png)

*Inizio della generazione: init passa a '0', il registro inizia a scorrere*

</div>

<div align="center">

![Simulazione 4](screenshots/Immagine%202025-01-25%20105328.png)

*Evoluzione della sequenza PN_code nei primi cicli*

</div>

<div align="center">

![Simulazione 5](screenshots/Immagine%202025-01-25%20105530.png)

*Sequenza PN in corso — andamento dei bit interni Q1..Q15*

</div>

<div align="center">

![Simulazione 6](screenshots/Immagine%202025-01-25%20105702.png)

*Vista allargata: periodicità della sequenza pseudo-casuale*

</div>

<div align="center">

![Simulazione 7](screenshots/Immagine%202025-01-25%20105807.png)

*Dettaglio dei tap XOR (Q5, Q7, Q8, Q9, Q13, Q15)*

</div>

<div align="center">

![Simulazione 8](screenshots/Immagine%202025-01-25%20105850.png)

*Verifica della lunghezza del periodo: dopo 32767 cicli la sequenza si ripete*

</div>

<div align="center">

![Simulazione 9](screenshots/Immagine%202025-01-25%20110058.png)

*Conferma del periodo massimo: PN_code ritorna al valore iniziale*

</div>

<div align="center">

![Simulazione 10](screenshots/Immagine%202025-01-25%20110702.png)

*Analisi della distribuzione dei bit: bilanciamento 0/1 nella sequenza*

</div>

<div align="center">

![Simulazione 11](screenshots/Immagine%202025-01-25%20110940.png)

*Vista finale della simulazione ModelSim — 0 errori, 1 warning*

</div>

### Log di simulazione (ModelSim)

```
vsim -gui work.png_tb
# Start time: 10:45:47 on Jan 25,2025
# Loading work.png(structural)
# Loading work.mux(beh)
# Loading work.d_flip_flop(beh)
# End time: 11:01:20 on Jan 25,2025, Elapsed time: 0:15:33
# Errors: 0, Warnings: 1
```

---

## ⚙️ Sintesi con Vivado

### Target device

| Parametro | Valore |
|---|---|
| FPGA | **Xilinx Zynq-7010** |
| Part | `xc7z010clg400-1` |
| Tool | Vivado 2022.2 |
| Vincolo di clock | 10 ns (100 MHz) |

### Screenshot Vivado — Schematico e risultati

<div align="center">

![Vivado 1](screenshots/Immagine%202025-01-25%20171421.png)

*Schematico elaborato da Vivado dopo la sintesi*

</div>

<div align="center">

![Vivado 2](screenshots/Immagine%202025-01-26%20112119.png)

*Sintesi completata: vista del design su Vivado*

</div>

<div align="center">

![Vivado 3](screenshots/Immagine%202025-01-26%20120655.png)

*Report di utilizzo risorse FPGA dopo la sintesi*

</div>

---

## 📊 Risultati di utilizzo FPGA

Dopo la sintesi con Vivado 2022.2 sul target **xc7z010clg400-1**:

### Slice Logic

| Risorsa | Usate | Disponibili | Utilizzo |
|---|---|---|---|
| Slice LUTs | **16** | 17600 | **0.09%** |
| LUT as Logic | 16 | 17600 | 0.09% |
| Slice Registers (FF) | **15** | 35200 | **0.04%** |
| Register as Flip-Flop | 15 | 35200 | 0.04% |
| Block RAM | 0 | 60 | 0.00% |
| DSPs | 0 | 80 | 0.00% |

### Primitivi utilizzati

| Primitiva | Quantità | Descrizione |
|---|---|---|
| `LUT3` | 15 | Look-Up Table 3 ingressi (MUX + XOR tap) |
| `LUT6` | 1 | Look-Up Table 6 ingressi (XOR finale a 5 ingressi) |
| `LUT1` | 1 | Look-Up Table 1 ingresso (inversione) |
| `FDCE` | 15 | D Flip-Flop con Clock Enable e Reset asincrono |

> ✅ Il design è **estremamente compatto**: occupa meno dello 0.1% delle risorse del Zynq-7010.

---

## 🚀 Come eseguire il progetto

### Simulazione con ModelSim

1. Aprire ModelSim e caricare il progetto `modelsim/PNG.mpf`
2. Compilare i sorgenti nell'ordine:
   ```
   vcom src/D_flip_flop.vhd
   vcom src/Mux.vhd
   vcom src/PNG.vhd
   vcom tb/PNG_tb.vhd
   ```
3. Avviare la simulazione:
   ```
   vsim work.PNG_tb
   run -all
   ```

### Sintesi con Vivado

1. Aprire Vivado 2022.2
2. Caricare il progetto: `Vivado/project_PNG/project_PNG.xpr`
3. Eseguire **Run Synthesis** (il vincolo di clock è già configurato in `PNG_constraints.xdc`)
4. Eseguire **Open Synthesized Design** per visualizzare lo schematico e il report di utilizzo

---

## 📚 Riferimenti

- Molinari, *Sequenze pseudo-casuali* — dispensa universitaria
- Xilinx, *Vivado Design Suite User Guide: Synthesis* (UG901)
- IEEE Std 1076-2008, *VHDL Language Reference Manual*
- M. Davio, J.-P. Deschamps, A. Thayse, *Discrete and Switching Functions* — LFSR theory

---

## 👤 Autore

**Klaudio Caca**  
Progetto realizzato nel gennaio 2025.

---

<div align="center">

*Generatore di sequenze PN — LFSR 15-bit — VHDL — Zynq-7010*

</div>
