# DeppVsAmber-Sentiment-Analysis

# Depp v. Heard — Twitter Sentiment & Text Analysis

A text-mining and sentiment-analysis project in R that examines how Twitter discussed
the 2022 Depp v. Heard defamation trial. Tweets are split by who they mention — **Johnny
Depp**, **Amber Heard**, or **both** — and compared across volume, vocabulary, distinctive
terms, emotion, and sentiment over time.

The analysis uses the **`fulltrialdata.csv`** file from the [Johnny Depp and Amber Heard
Twitter Data](https://www.kaggle.com/datasets/lukegroves/johnny-depp-and-amber-heard-twitter-data?select=fulltrialdata.csv) dataset on Kaggle (compiled by Luke Groves,
CC0: Public Domain), which contains 18,323 English-language tweets spanning
**Apr 27 – May 13, 2022** — a 17-day window of active courtroom testimony and high public
engagement.

---

## What it does

The analysis script (`DeppVsAmber.R`) ingests a corpus of trial-era tweets, tags each
tweet by mention group, tokenizes the text, and produces six visualizations:

| Output | What it shows |
| --- | --- |
| `volume.png` | Daily tweet volume per mention group (`amber`, `depp`, `mix`) over the trial window. |
| `wordcloud.png` | Side-by-side word clouds of the most frequent terms for `amber` vs `depp`. |
| `top_words.png` | Most frequent words per group, **normalized** to proportions and faceted by month (2022-04 vs 2022-05). |
| `tfidf.png` | Distinctive vocabulary per group via **TF-IDF** — words that characterize one group relative to the other. |
| `nrc.png` | Emotion profile per group using the **NRC** lexicon (anger, fear, trust, sadness, anticipation, disgust, joy, surprise), user-weighted. |
| `sentiment.png` | Relative sentiment over time per group using the **AFINN** lexicon, user-weighted. |

### Notes on method

- **Mention groups.** Tweets are bucketed into `amber` (mentions Heard only), `depp`
  (mentions Depp only), and `mix` (mentions both). The `mix` group dominates raw volume,
  so it appears in the volume plot but is dropped from the per-group sentiment/emotion
  comparisons, which contrast `depp` vs `amber` directly.
- **User-weighting.** Sentiment and emotion are *user-weighted* rather than tweet-weighted,
  which limits the influence of high-frequency posters and prevents a handful of accounts
  from skewing the aggregate signal.
- **Negative baseline.** Because trial vocabulary is intrinsically negative ("abuse,"
  "violence," "victim," "defamation"), AFINN scores sit below zero for both groups. The
  `sentiment.png` subtitle flags this — the meaningful read is the **`depp` vs `amber`
  contrast**, not the absolute sign.
- **Normalization.** Word-frequency comparisons use proportions, not raw counts, so the
  larger group doesn't automatically appear to use every word more.

---

## Requirements

- **R** ≥ 4.1 (tested on a recent release)
- The following packages:

```r
install.packages(c(
  "tidyverse",   # dplyr, ggplot2, tidyr, readr, stringr, purrr
  "tidytext",    # tokenization, lexicons, bind_tf_idf
  "textdata",    # downloads AFINN and NRC lexicons
  "lubridate",   # date handling
  "ggwordcloud", # word cloud layer for ggplot (or "wordcloud")
  "scales"       # axis formatting
))
```

> **Lexicons:** The first time you use AFINN and NRC via `tidytext::get_sentiments()`,
> `textdata` will prompt you to download and accept the lexicon licenses. Run the script
> interactively once so you can accept these prompts.

---

## Input data

The analysis uses publicly available Twitter (X) data from the **Johnny Depp and Amber
Heard Twitter Data** dataset on Kaggle, compiled by user **Luke Groves** and released under
**CC0: Public Domain**. Specifically, it reads the **`fulltrialdata.csv`** file (~18.4 MB,
90 columns), which contains **18,323 English-language tweets** spanning **Apr 27 – May 13,
2022**.

Relevant columns used by the script include:

| Column | Description |
| --- | --- |
| `user_id` | Tweet author ID (used for user-weighting) |
| `status_id` | Unique tweet ID |
| `created_at` | Timestamp (e.g. `2022-04-29T02:46:44Z`) |
| `screen_name` | Author handle |
| `text` | Tweet body |

> **Getting the data:** download `fulltrialdata.csv` from the Kaggle dataset and place it
> where the script expects it (e.g. a `data/` directory). Because the file falls under
> the platform's terms, it is typically kept out of version control. *(Confirm the exact
> path your script reads against your code.)*

### Preprocessing

The raw tweets are cleaned and reshaped before analysis:

1. **Clean text** — lowercase; strip URLs, HTML entities, punctuation, non-alphabetic
   characters, and extra whitespace.
2. **Filter & group** — keep only tweets referencing Johnny Depp or Amber Heard, then
   assign each to one of three groups by keyword: `depp`, `amber`, or `mix` (both mentioned).
3. **Tokenize & lemmatize** — split into individual words and reduce them to base forms.
4. **Remove stopwords** — standard English stopwords plus a custom domain list (names,
   platform terms, and generic trial vocabulary).

---

## Project structure

```
.
├── DeppVsAmber.R      # main analysis script
├── data/              # input tweets (not tracked)
│   └── fulltrialdata.csv   # from Kaggle (Luke Groves, CC0)
├── outputs/           # generated plots
│   ├── volume.png
│   ├── wordcloud.png
│   ├── top_words.png
│   ├── tfidf.png
│   ├── nrc.png
│   └── sentiment.png
└── README.md
```

---

## Interpreting the results

A few patterns visible in the outputs:

- **Volume** is overwhelmingly driven by tweets mentioning both parties (`mix`), spiking
  around late April and again in early May; single-mention tweets are comparatively rare.
- **Vocabulary** for both groups centers on the trial itself — *abuse, violence, victim,
  domestic, article* — but the distinctive (TF-IDF) terms diverge: the `amber` group skews
  toward *defamation / defendant / psychologist / personality (disorder)* language, while
  the `depp` group skews toward *meet / text / apology / support* language.
- **Emotion** profiles (NRC) differ in shape: trust and anticipation register higher for
  one group, anger and fear for the other — useful as a relative contrast rather than an
  absolute claim.

These are descriptive lexicon-based signals, **not** measures of truth or guilt. Sarcasm,
quotes, and context are not captured by bag-of-words sentiment, and lexicon methods are
known to misread negation and irony — both common in trial discourse.

---

## Limitations & ethics

- Lexicon sentiment ignores negation, sarcasm, and context, which are pervasive here.
- Mention-based grouping is a coarse proxy for stance; a tweet mentioning Heard may be
  defending or attacking her.
- This is a snapshot of a specific, contentious public moment. Results describe *online
  discourse*, not the people involved or the merits of the case.
