-- site.hs
-- Configuration for my personal web-site and blog.
--
-- Author: Kevin Dungs <kevin@dun.gs>
-- Date:   2014-04-05

{-# LANGUAGE OverloadedStrings #-}
import Control.Monad (liftM)
import Data.Monoid (mappend)
import Hakyll


main :: IO ()
main = hakyll $ do
  -- Static resources
  --- Images
  match "images/*" $ do
    route idRoute
    compile copyFileCompiler
  --- Style sheets
  match "css/*" $ do
    route idRoute
    compile compressCssCompiler
  -- About page
  match "about.md" $ do
    route $ setExtension "html"
    compile $ pandocCompiler >>= loadAndApplyTemplate "templates/default.html" defaultContext
                             >>= relativizeUrls
  -- Posts
  match "posts/*" $ do
    route $ setExtension "html"
    compile $ pandocCompiler >>= loadAndApplyTemplate "templates/default.html" postCtx 
                             >>= relativizeUrls
  -- Archives
  create ["archive.html"] $ do
    route idRoute
    compile $ do
      posts <- recentFirst =<< loadAll "posts/*"
      let archiveCtx = listField "posts" postCtx (return posts) `mappend`
                       constField "title" "Archives" `mappend`
                       defaultContext
      makeItem "" >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
                  >>= loadAndApplyTemplate "templates/default.html" archiveCtx
                  >>= relativizeUrls
  -- Index
  match "index.html" $ do
    route idRoute
    compile $ do
      posts <- liftM (take 3) $ recentFirst =<< loadAll "posts/*"
      let indexCtx = listField "posts" postCtx (return posts) `mappend`
                     constField "title" "Home" `mappend`
                     defaultContext
      getResourceBody >>= applyAsTemplate indexCtx
                      >>= loadAndApplyTemplate "templates/default.html" indexCtx
                      >>= relativizeUrls
  -- Templates
  match "templates/*" $ compile templateCompiler


-- Custom contexts
postCtx :: Context String
postCtx = dateField "date" "%F" `mappend`
          defaultContext
