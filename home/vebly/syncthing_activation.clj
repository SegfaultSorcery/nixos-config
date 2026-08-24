(require '[clojure.data.xml :as xml]
         '[clojure.string :as str]
         '[babashka.http-client :as http]
         '[babashka.fs :as fs]
         '[cheshire.core :as json])


(defn- xml-get-in [path node] 
  (if (empty? path)
    node
    (let [[p & ps] path
          match ( ->> (:content node)
                 (filter map?)
                 (filter #(= p (:tag %)))
                 first)
          ]
      (recur ps match))))

(defn read-config [path]
  (let [xml-tree (xml/parse-str (slurp path))]
    {:url (str "http://"
                   (->> xml-tree
                        (xml-get-in [:gui :address])
                        :content
                        first)
                   "/rest")
     :api-key (->> xml-tree
                   (xml-get-in [:gui :apikey])
                   :content
                   first)

     }))

(defn get-secrets [path]
  (let [fname (str (fs/file-name path))]
    (if (fs/directory? path)
      {fname (into {} (map get-secrets (fs/list-dir path)))}
      [fname (str/split-lines (slurp (str path)))])))


(defn device->api [[key val]]
  {"name" key 
   "deviceID" (first (get val "id"))
   "addresses" (get val "addresses")})


(defn folder->api [device-name->id [key val]]
  {"label" key
   "id" key
   "devices" (mapv
              (fn [device] {"deviceID" (device-name->id device)})
              (get val "devices") )})


(defn put-json [url headers body]
  (try
    {:ok true
     :value (http/put url
             {:headers headers
              :body (json/generate-string body)}
             )}
    (catch Exception e
      {:ok false
       :error (.getMessage e)}))
  )

(defn report-result [name result]
  (if (:ok result)
    (println "Successfully updated" name)
    (println "Failed to update" name "," (:error result))))

(def config-xml-path "/home/vebly/.config/syncthing/config.xml")
(def secrets-path "/run/secrets/syncthing")

(defn -main []
  (let [config (read-config config-xml-path) 
        header {"X-API-Key" (:api-key config)}
        url (:url config)

        secrets (second (first (get-secrets secrets-path))); 
        folder-secrets (get secrets "folders")
        device-secrets (get secrets "devices")

        device-body (mapv device->api device-secrets)
        device-name->id (fn [dname] (first (get-in device-secrets [dname "id"])))
        folder-body (mapv #(folder->api device-name->id %) folder-secrets)]

    (report-result
     "devices"
     (put-json (str url "/config/devices") header device-body))

    (report-result
     "folders"
     (put-json (str url "/config/folders") header folder-body))))

(comment
  (def config-xml-path "/home/vebly/.config/syncthing/config.xml")
  (def secrets-path "/run/secrets/syncthing.bak/")
  (def config (read-config config-xml-path)) 
  (def header {"X-API-Key" (:api-key config)})
  (def url (:url config))
  (def secrets (second (first (get-secrets secrets-path)))) 
  (def folder-secrets (get secrets "folders"))
  (def device-secrets (get secrets "devices"))
  (def device-body (mapv device->api device-secrets))
  (def device-name->id (fn [dname] (first (get-in device-secrets [dname "id"]))))
  (def folder-body (mapv #(folder->api device-name->id %) folder-secrets)))

(-main)
