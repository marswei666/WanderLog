// 云函数：syncUserStats
// 部署到腾讯云 CloudBase 云函数，Node.js 18 环境
// 入口函数名：main

const cloudbase = require("@cloudbase/node-sdk");

exports.main = async (event, context) => {
  const app = cloudbase.init({ env: process.env.SCF_TCB_ENV });
  const db = app.database();
  const collection = db.collection("user_stats");

  let body;
  try {
    body = typeof event.body === "string" ? JSON.parse(event.body) : event.body;
  } catch (e) {
    return { statusCode: 400, body: { error: "Invalid JSON" } };
  }

  const { userUUID, userName, totalCheckIns, totalCountries, totalCities, updatedAt, platform } = body;

  if (!userUUID) {
    return { statusCode: 400, body: { error: "userUUID is required" } };
  }

  try {
    const existing = await collection.where({ userUUID }).get();

    if (existing.data.length > 0) {
      await collection.doc(existing.data[0]._id).update({
        userName,
        totalCheckIns,
        totalCountries,
        totalCities,
        updatedAt,
        platform,
      });
    } else {
      await collection.add({
        userUUID,
        userName,
        totalCheckIns,
        totalCountries,
        totalCities,
        updatedAt,
        platform,
      });
    }

    return { statusCode: 200, body: { success: true } };
  } catch (err) {
    return { statusCode: 500, body: { error: err.message } };
  }
};
