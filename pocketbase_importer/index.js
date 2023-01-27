import PocketBase from "pocketbase";
import fs from "fs";
import { parse } from "csv-parse";
const pb = new PocketBase("http://pocketbase.arz.st");

fs.createReadStream("../books_data.csv").pipe(
  parse({ delimiter: ",", from_line: 2 }, async (err, data) => {
    if (err) {
      console.error(err);
      return;
    }
    const entries = data.map((element) => {
      return {
        page: element[0],
        index: element[1],
        relative_url: element[2],
        full_url: element[3],
        title: element[4],
        author: element[5],
        summary: element[6],
        author_information: element[7],
      };
    });
    entries.forEach(async (entry) => {
      try {
        await pb.collection("books").create(entry, { $autoCancel: false });
      } catch (error) {
        console.error(entry, error);
      }
    });
  })
);
