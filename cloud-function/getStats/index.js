// 云函数：getStats
// 用于网页读取所有用户统计数据
// 入口函数名：main

const cloudbase = require("@cloudbase/node-sdk");

exports.main = async (event, context) => {
  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
  };

  if (event.httpMethod === "OPTIONS" || (event.requestContext && event.requestContext.http && event.requestContext.http.method === "OPTIONS")) {
    return { statusCode: 204, headers: corsHeaders, body: "" };
  }

  const app = cloudbase.init({ env: process.env.SCF_TCB_ENV });
  const db = app.database();
  const collection = db.collection("user_stats");

  try {
    const res = await collection.orderBy("totalCheckIns", "desc").limit(100).get();
    return {
      statusCode: 200,
      headers: { "Content-Type": "application/json", ...corsHeaders },
      body: { success: true, data: res.data },
    };
  } catch (err) {
    return {
      statusCode: 500,
      headers: corsHeaders,
      body: { success: false, error: err.message },
    };
  }
};
