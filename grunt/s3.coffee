module.exports = {
  options:
    key: process.env.S3_KEY
    secret: process.env.S3_SECRET
    bucket: process.env.S3_BUCKET
    access: 'private'
    headers:
      # Two Year cache policy (1000 * 60 * 60 * 24 * 730).
      "Cache-Control": "max-age=630720000, public",
      "Expires": new Date(Date.now() + 63072000000).toUTCString()
  dist:
    upload: [
      src: "dist/*.crx"
      dest: process.env.S3_FOLDER
    ]
}
