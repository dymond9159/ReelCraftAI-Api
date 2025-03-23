const fs = require("fs");

export const adminData = JSON.parse(
  fs.readFileSync("./public/seeds/admin-data.json", "utf8"),
);
