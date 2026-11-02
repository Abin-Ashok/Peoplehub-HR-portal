const { CognitoJwtVerifier } = require("aws-jwt-verify");

const verifier = CognitoJwtVerifier.create({
  userPoolId: process.env.COGNITO_USER_POOL_ID,
  tokenUse: "access",
  clientId: process.env.COGNITO_CLIENT_ID
});

async function requireAuth(req, res, next) {
  const header = req.headers.authorization || "";
  const [scheme, token] = header.split(" ");

  if (scheme !== "Bearer" || !token) {
    return res.status(401).json({
      error: "Authentication required."
    });
  }

  try {
    req.auth = await verifier.verify(token);
    next();
  } catch {
    return res.status(401).json({
      error: "Invalid or expired access token."
    });
  }
}

module.exports = { requireAuth };
