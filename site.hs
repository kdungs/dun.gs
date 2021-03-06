{-# LANGUAGE OverloadedStrings #-}

import Data.Monoid (mappend)
import Hakyll

cfg :: Configuration
cfg = defaultConfiguration {
  deployCommand = "rsync -avz -e ssh ./_site/ uberspace:./html/"
}

postCtx :: Context String
postCtx =
  teaserField "teaser" "content" `mappend`
  dateField "date" "%0Y-%m-%d" `mappend`
  defaultContext

main :: IO ()
main = hakyllWith cfg $ do
  match "templates/*" $ compile templateCompiler

  match "style.css" $ do
    route idRoute
    compile compressCssCompiler

  match "images/**/*" $ do
    route idRoute
    compile copyFileCompiler

  match "posts/*.md" $ do
    route $ setExtension "html"
    compile $ pandocCompiler
      >>= saveSnapshot "content"
      >>= loadAndApplyTemplate "templates/post.html"    postCtx
      >>= loadAndApplyTemplate "templates/default.html" postCtx
      >>= relativizeUrls

  match "index.html" $ do
    route idRoute
    compile $ do
      posts <- recentFirst =<< loadAll "posts/*"
      let indexCtx = listField "posts" postCtx (return posts) `mappend`
                     constField "title" "Home" `mappend`
                     defaultContext
      getResourceBody
        >>= applyAsTemplate indexCtx
        >>= loadAndApplyTemplate "templates/default.html" indexCtx
        >>= relativizeUrls
