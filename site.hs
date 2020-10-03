{-# LANGUAGE OverloadedStrings #-}

import Data.Monoid (mappend)
import Hakyll

cfg :: Configuration
cfg = defaultConfiguration {
  deployCommand = "rsync -avz -e ssh ./_site/ uberspace:./html/"
}

postCtx :: Context String
postCtx =
  dateField "date" "%0Y-%m-%d" `mappend`
  defaultContext

main :: IO ()
main = hakyllWith cfg $ do
  match "templates/*" $ compile templateCompiler

  match "images/**/*" $ do
    route   idRoute
    compile copyFileCompiler

  match "posts/*" $ do
    route $ setExtension "html"
    compile $ pandocCompiler
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
