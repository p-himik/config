#!/usr/bin/env bb
(ns llm-summary
  "Requires for the OPENROUTER_API_KEY environment variable to be set."
  (:require [babashka.fs :as fs]
            [babashka.http-client :as http]
            [babashka.process :as p]
            [cheshire.core :as json]
            [clojure.pprint :as pprint]
            [clojure.string :as str]))

(def url "https://openrouter.ai/api/v1/chat/completions")
(def api-key (System/getenv "OPENROUTER_API_KEY"))
(assert api-key)

(def system-prompt
  "You are a text summarization system that produces itemized summaries from transcript text.
Rules:
1. Exclude advertisements, self-promotions, sponsorships, and digressions.
2. Keep only factual or conceptual content relevant to the main topic.
3. Output as a plain-text numbered list.
4. Wrap lines to 80 columns while preserving indentation within every list item.
5. Do not enclose the output in code blocks or quotes.
6. Use ANSI escape codes for emphasis:
   - Bold important terms with \\x1b[1m...\\x1b[0m
   - Dim secondary notes with \\x1b[2m...\\x1b[0m
   - Use colors for important terms
   - Use different colors for different terms, and same colors for same terms
7. Preserve chronological order where possible.
8. Use simple ASCII quotes and double quotes instead of Unicode symbols for quotes.
9. Condense the output so it can serve as a short executive summary.
10. No commentary, no headers, no concluding remarks.")

(defn split-subtitle-text-into-blocks [text]
  (str/split text #"\n\n+"))

(defn parse-subtitle-block [text]
  (when-not (some #(str/starts-with? text %) ["WEBVTT" "STYLE" "REGION" "NOTE"])
    (->> (str/split-lines text)
         ;; Removing all the headers.
         (drop-while #(not (re-matches #".*-->.*" %)))
         (drop 1)
         ;; Remove timestamp and class tags.
         ;; Leaving the rest of the tags in just in case they provide
         ;; some contextual information, like emphasis.
         (map #(str/replace % #"<(\d[\d:\.]+|/?c(\.[^>]*)?)>" ""))
         (remove #(re-matches #" *" %)))))

(defn get-summary [text]
  (let [body {:model    "openrouter/auto"
              :messages [{:role    "system"
                          :content system-prompt}
                         {:role    "user"
                          :content text}]}

        {:keys [provider model choices usage]}
        (-> (http/post url
                       {:headers {:content-type  "application/json"
                                  :authorization (str "Bearer " api-key)}
                        :body    (json/encode body)})
            (:body)
            (json/parse-string true))]
    {:details {:provider provider
               :model    model
               :usage    usage}
     :summary (-> (get-in choices [0 :message :content])
                  (str/replace #"(\\x1b|\\033)\[" "\033["))}))

(defn get-yt-video-summary [url]
  (let [tmp (fs/create-temp-file {:prefix "yt-summary."})
        tmp-dir (str (.getParent tmp))]
    (try
      (p/shell "yt-dlp --write-auto-subs --write-subs --sub-format vtt --skip-download" "--sub-langs" ".*-orig,en" url "-o" tmp)
      (let [[text-file & other-files] (fs/glob tmp-dir (str (.getFileName tmp) ".*.vtt"))
            blocks (-> (slurp (str text-file))
                       (split-subtitle-text-into-blocks))
            text (->> blocks
                      (mapcat parse-subtitle-block)
                      (dedupe)
                      (str/join "\n"))]
        (when other-files
          (binding [*out* *err*]
            (println "Warning: multiple subtitle files exist, reading only" text-file)))
        (get-summary text))
      (finally
        (run! fs/delete-if-exists (fs/glob tmp-dir (str (.getFileName tmp) "*")))))))

(defn get-clipboard-text []
  (:out (p/shell {:out :string} "xclip -selection clipboard -o")))

(defn get-clipboard-text-summary []
  (get-summary (get-clipboard-text)))

(defn youtube-url? [maybe-url]
  (or (re-matches #"https?://(www\.)?(youtu\.be|youtube\.com)/.*" maybe-url)
      ;; A local Invidious instance.
      (str/starts-with? maybe-url "http://127.0.0.1:3000/watch?v=")))

(let [[mode url] (case (count *command-line-args*)
                   0 [:clipboard nil]
                   1 (let [url (first *command-line-args*)]
                       (assert (youtube-url? url))
                       [:youtube url]))
      {:keys [details summary]} (case mode
                                  :youtube (get-yt-video-summary url)
                                  :clipboard (get-clipboard-text-summary))]
  (println)
  (pprint/pprint details)
  (println)
  (println summary))
