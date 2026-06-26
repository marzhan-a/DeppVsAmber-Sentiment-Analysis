library(tidyverse)
library(tidytext)
library(textstem)
library(ggplot2)
library(ggwordcloud)
library(lubridate)
library(textdata)

# =====================================================================
# LOAD  (status_id / user_id as character to avoid float ID corruption)
# =====================================================================
df <- read.csv("/Users/marzanadylbaeva/Desktop/Documents/CSS/Projects/Final Project/fulltrialdata.csv",
               stringsAsFactors = FALSE,
               colClasses = c((user_id = "character"), (status_id = "character")))
# ============================================================
# PUBLIC-OPINION FILTERING  (to avoid conclusions be about
# the press instead of public)
# ============================================================
personal <- c("Twitter for iPhone", "Twitter for Android", "Twitter for iPad",
              "Twitter for Mac", "Twitter Web App")

media_accounts <- c(
  "ItsDeanBlundell", "SafeHorizon", "UCLA_Law", "FoxNews", "enews", "CBSNews",
  "TMZ", "PerezHilton", "latimes", "Newsweek", "THR", "Variety", "nypost",
  "Complex", "CP24", "iHeartRadio", "JackPosobiec", "etnow", "rtenews",
  "DEADLINE", "nationalpost", "WhatsTrending", "IndieWire", "CityNewsTO",
  "vulture", "JOEdotie", "ETCanada", "MorningBrew", "SharylAttkisson",
  "WGNNews", "7News", "FDRLST", "danabrams", "JeffreyGoldberg", "oxygen",
  "TMZLive", "KlasfeldReports", "TheWrap", "consequence", "smerconish",
  "News4SA", "MARCAinENGLISH", "jonathanchait", "BrianWFoster", "Outkick",
  "lhfang", "7NewsDC", "EWDolan", "KUTV2News", "KFOX14", "PopCrush", "CBS12",
  "NBC10", "elephantjournal", "BarstoolHubbs", "HotlineJosh", "KTULNews",
  "KSL5TV", "KUSINews", "ReutersLegal", "jackshafer", "lawcrimenews",
  "AsraNomani", "AP4Liberty", "TND", "NewsNation", "PaulRudnickNY", "carney",
  "mynbc15", "cduhigg", "NicoleLapin", "MarlowNYC", "LawCrimeNetwork",
  "Eve_Barlow", "kattenbarge", "fox11news", "RealTimMalcolm", "andysignore",
  "Josiensor", "CourtTV", "brosandprose", "sundayworld", "jswatz",
  "RSVPMagazine", "WeekesPrincess", "NewsLitProject", "TomNamako", "ejdickson",
  "InsiderNews", "Alex_Panetta", "YahooCanadaNews", "EricMGarcia",
  "HardFactorNews", "ProSportsExtra", "77WABCradio", "hot96tweets",
  "iproposethis", "DavidRutz", "benpershing", "JSS98Rock", "FindLawConsumer",
  "jtylerconway", "CBS4Local", "mytalk1071", "tv_brendon", "Angenette5",
  "xpangler", "PLMuse", "StarPittsburgh", "PureCountry94", "kimatv",
  "sharonwaxman", "JayShams", "gbrockell", "artipatel", "dennisjromero",
  "anoushasakoui", "antoniacere", "AbcarianLAT", "Maggie_Vespa", "WGXAnews",
  "KennieBassWCHS", "itsmelissabrown", "arcticninjapaul", "scottdeveau",
  "TheNolaChick", "TheGrowthOp", "STAR1025", "jodieobrien", "JaBogen",
  "Elias7News", "laracroftbarbie", "elvialimon", "Cpatrickis", "sierragillespie",
  "JuliaFello", "morganbaila", "CJancelewicz", "livenowfox", "sara_bee",
  "dromanber", "pbmelendez", "lauraftrujillo", "Ashlie7News", "jfitzgibbon",
  "HighSierraMan", "AisleSeat", "HarringtonBecca", "Megan_Palin", "danieljevon",
  "DMoritzRabson", "JoeJohnsonOnAir", "HernandezMJae", "juliaajohnson_",
  "HMongilio", "_pbnjer", "mqbrady", "JackDIsidoro", "joshkelliott", "JiaWertz",
  "elizameryl", "AlisonReporting", "carolinehouck", "olivnelson", "anne_most",
  "xoxo_glenn", "WeinbergLindsay", "kintarasu", "kelseymaura_", "jokictasha",
  "hollyhonderich", "morgangoldwich", "madebytam", "twhitakerwrbl", "PeterSuciu",
  "SaharaReporters", "TimRunsHisMouth", "JonahDispatch", "ARmastrangelo",
  "davejorgenson", "yannispappas", "fawfulfan", "mayradiasgomes", "chrissyclark_",
  "kimmasters", "nichcarlson", "MariekeWalsh", "davebiddle", "MattBelloni",
  "timcarman", "maxnesterak", "ErickaAndersen", "Arightside", "soniamoghe",
  "atRachelGilmore", "Chloe_Melas", "corinne_perkins", "NewsyNatalie",
  "katieleebarlow", "ReporterAmber", "BThomps81", "TishaLewis", "jimbourg",
  "EmilyYahr", "apiotrowski9", "MarcusBlimi", "DariusRadzius", "NicRodriguez",
  "matthewkassel", "markhdaniell", "JustinoAguila", "MikestewartAP", "Th3Claude",
  "nfallslangley"
)

# ============================================================
# CLEAN + GROUP (group is detected on raw text incl. @handles,
# BEFORE stripping, so replies to @JohnnyDepp count as Depp)
# ============================================================
tweets_clean <- df %>%
  filter(is_retweet == FALSE,
         lang == "en",
         source %in% personal,
         !(screen_name %in% media_accounts)) %>%
  transmute(
    id          = status_id,
    user_id     = user_id,
    screen_name = screen_name,
    created_at  = as.Date(created_at),
    raw         = str_to_lower(text)
  ) %>%
  mutate(
    group = case_when(
      str_detect(raw, "depp|johnny") & str_detect(raw, "amber|heard") ~ "mix",
      str_detect(raw, "depp|johnny") ~ "depp",
      str_detect(raw, "amber|heard") ~ "amber",
      TRUE ~ "none"
    ),
    tweet = str_remove_all(raw, "https?\\S+"),
    tweet = str_remove_all(tweet, "[@#]\\w+"),
    tweet = str_replace_all(tweet, "won't", "will not"),
    tweet = str_replace_all(tweet, "can't", "cannot"),
    tweet = str_replace_all(tweet, "shan't", "shall not"),
    tweet = str_replace_all(tweet, "n't", " not"),
    tweet = str_replace_all(tweet, "'re", " are"),
    tweet = str_replace_all(tweet, "'ve", " have"),
    tweet = str_replace_all(tweet, "'ll", " will"),
    tweet = str_replace_all(tweet, "'m", " am"),
    tweet = str_remove_all(tweet, "&amp;"),
    tweet = str_remove_all(tweet, "'"),
    tweet = str_remove_all(tweet, "[^a-z\\s]"),
    tweet = str_squish(tweet)
  ) %>%
  filter(group != "none", tweet != "") %>%
  distinct(tweet, .keep_all = TRUE) %>%
  add_count(user_id, name = "user_n") %>%
  mutate(user_weight = 1 / user_n)

cat("Tweets:", nrow(tweets_clean),
    "| Users:", n_distinct(tweets_clean$user_id), "\n")
print(table(tweets_clean$group))

# ====================================================================================
# TOKENS
#   tokens_lex  : un-lemmatized, AFINN words + negators kept -> sentiment / NRC
#   tokens_freq : lemmatized, full + domain stop-words -> frequency / TF-IDF / clouds
# ====================================================================================
data(stop_words)
afinn <- get_sentiments("afinn")
nrc   <- get_sentiments("nrc")

negators <- c("not", "no", "never", "none", "nor", "cannot")

lexicon_stop <- stop_words %>%
  anti_join(afinn, by = "word") %>%
  filter(!word %in% negators)

additional_stopwords <- tibble(token = c(
  "depp", "johnny", "heard", "amber", "heards", "depps", "ambers",
  "amberheard", "johnnydepp", "deppamber", "deppvsheard", "deppvheard",
  "johnnydeppvsamberheard", "johnnydeppamberheardtrial", "amberheardisaliar",
  "trial", "court", "testimony", "testify", "lawyer", "lawyers",
  "youtube", "tiktok", "video", "watch", "watching", "ripley", "media", "news",
  "people", "team", "day", "time", "week", "life",
  "real", "start", "finally", "continue", "late",
  "im", "ive", "ill", "hes", "shes", "dont", "didnt",
  "rt", "amp", "https", "co", "t", "lol", "lmao", "omg",
  "sign", "change", "line", "quote", "record", "call", "hear",
  "speak", "talk", "follow", "post", "question", "live", "million", "claim", "fan",
  "aclu", "aclus", "disney", "netflix",
  "elon", "musk", "elonmusk", "carino", "anna", "elizabeth",
  "agent", "expert", "medium", "space", "voice", "audio",
  "career", "aftermath", "describe", "donate", "revise",
  "australias", "jeweleldoras", "eastern"
))

tokens_lex <- tweets_clean %>%
  unnest_tokens(token, tweet) %>%
  anti_join(lexicon_stop, by = c("token" = "word"))

tokens_freq <- tweets_clean %>%
  unnest_tokens(token, tweet) %>%
  mutate(token = lemmatize_words(token)) %>%
  anti_join(stop_words, by = c("token" = "word")) %>%
  anti_join(additional_stopwords, by = "token")

# ===================
# 1. VOLUME OVER TIME  
# ===================
volume_time <- tweets_clean %>%
  count(created_at, group)

volume_plot <- ggplot(volume_time, aes(created_at, n, color = group)) +
  geom_line(linewidth = 1) + geom_point() +
  scale_x_date(date_breaks = "3 days", date_labels = "%b %d") +
  labs(title = "Tweet Volume Over Time by Mention",
       x = "Date", y = "Tweets", color = "Group") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# =======================================
# 2. SENTIMENT OVER TIME  (user-weighted)
# =======================================
tweet_sentiment <- tokens_lex %>%
  left_join(afinn, by = c("token" = "word")) %>%
  group_by(id, group, created_at, user_weight) %>%
  summarise(score = mean(value, na.rm = TRUE), .groups = "drop") %>%
  mutate(score = replace_na(score, 0))

sentiment_time <- tweet_sentiment %>%
  filter(group %in% c("depp", "amber")) %>%
  group_by(created_at, group) %>%
  summarise(avg = weighted.mean(score, user_weight), .groups = "drop")

sentiment_plot <- ggplot(sentiment_time, aes(created_at, avg, color = group)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
  geom_line(linewidth = 1) + geom_point() +
  scale_x_date(date_breaks = "3 days", date_labels = "%b %d") +
  labs(title = "Relative Sentiment Over Time by Mention (AFINN, user-weighted)",
       subtitle = "Negative baseline reflects trial vocabulary; read depp vs amber as a contrast",
       x = "Date", y = "Avg AFINN score", color = "Group") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# ===============================
# 3. DISTINCTIVE WORDS (TF - IDF)
# ===============================
tfidf_words <- tokens_freq %>%
  filter(group %in% c("depp", "amber")) %>%
  count(group, token, sort = TRUE) %>%
  bind_tf_idf(token, group, n)

top_tfidf <- tfidf_words %>%
  group_by(group) %>%
  slice_max(tf_idf, n = 12, with_ties = FALSE) %>%
  ungroup() %>%
  mutate(token = reorder_within(token, tf_idf, group))

tfidf_plot <- ggplot(top_tfidf, aes(tf_idf, token, fill = group)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~group, scales = "free_y") +
  scale_y_reordered() +
  labs(title = "Distinctive Words by Mention (TF-IDF)", x = "tf-idf", y = NULL) +
  theme_minimal()

# ==========================
# 4. EMOTION PROFILE  (NRC)
# ==========================
nrc_profile <- tokens_lex %>%
  filter(group %in% c("depp", "amber")) %>%
  inner_join(nrc, by = c("token" = "word"), relationship = "many-to-many") %>%
  filter(!sentiment %in% c("positive", "negative")) %>%
  count(group, sentiment, wt = user_weight) %>%
  group_by(group) %>%
  mutate(prop = n / sum(n)) %>%
  ungroup()

nrc_plot <- ggplot(nrc_profile,
                   aes(reorder(sentiment, prop), prop, fill = group)) +
  geom_col(position = "dodge") +
  coord_flip() +
  labs(title = "Emotion Profile by Mention (NRC, user-weighted)",
       x = NULL, y = "Proportion of emotion words", fill = "Group") +
  theme_minimal()

# ===========================================
# 5. TOP WORDS BY GROUP x MONTH  (normalized)
# ===========================================
top_words <- tokens_freq %>%
  filter(group %in% c("depp", "amber")) %>%
  mutate(month = format(created_at, "%Y-%m")) %>%
  count(group, month, token) %>%
  group_by(group, month) %>%
  mutate(prop = n / sum(n)) %>%
  slice_max(prop, n = 10, with_ties = FALSE) %>%
  ungroup() %>%
  mutate(token = reorder_within(token, prop, interaction(group, month)))

topwords_plot <- ggplot(top_words, aes(prop, token, fill = group)) +
  geom_col(show.legend = FALSE) +
  facet_grid(month ~ group, scales = "free_y") +
  scale_y_reordered() +
  labs(title = "Top Words by Mention (Normalized)", x = "Proportion", y = NULL) +
  theme_minimal()

# ===========================
# 6. WORD CLOUDS  (per group)
# ===========================
set.seed(42)
cloud_data <- tokens_freq %>%
  filter(group %in% c("depp", "amber")) %>%
  count(group, token, sort = TRUE) %>%
  group_by(group) %>%
  slice_max(n, n = 70, with_ties = FALSE) %>%
  ungroup()

wordcloud_plot <- ggplot(cloud_data,
                         aes(label = token, size = n, color = group)) +
  geom_text_wordcloud(rm_outside = TRUE) +
  scale_size_area(max_size = 13) +
  facet_wrap(~group) +
  labs(title = "Word Clouds by Mention") +
  theme_minimal()

# =====
# SAVE
# =====
ggsave("volume.png",    volume_plot,    width = 10, height = 6, dpi = 300)
ggsave("sentiment.png", sentiment_plot, width = 10, height = 6, dpi = 300)
ggsave("tfidf.png",     tfidf_plot,     width = 9,  height = 6, dpi = 300)
ggsave("nrc.png",       nrc_plot,       width = 8,  height = 6, dpi = 300)
ggsave("top_words.png", topwords_plot,  width = 9,  height = 7, dpi = 300)
ggsave("wordcloud.png", wordcloud_plot, width = 10, height = 6, dpi = 300)