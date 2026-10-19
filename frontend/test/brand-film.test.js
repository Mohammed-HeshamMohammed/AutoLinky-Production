import test from 'node:test';
import assert from 'node:assert/strict';
import {FILM_DURATION,filmChapter,filmCopyLayers} from '../src/brandFilm.js';

const near=(actual,expected)=>assert.ok(Math.abs(actual-expected)<1e-10,`${actual} differs from ${expected}`);

test('film copy retraces each chapter handoff without stacking stories',()=>{
  for(let boundary=1;boundary<6;boundary++){
    const samples=Array.from({length:15},(_,i)=>(boundary*4-.35+i*.05)/FILM_DURATION);
    const forward=samples.map(progress=>filmCopyLayers(progress));
    const reverse=[...samples].reverse().map(progress=>filmCopyLayers(progress)).reverse();
    assert.deepEqual(forward,reverse);
    for(const layers of forward){
      assert.ok(layers.every(layer=>layer.opacity>=0&&layer.opacity<=1));
      assert.ok(layers.every(layer=>Math.abs(layer.y)<=14));
      assert.ok(layers.filter(layer=>layer.opacity>0).length<=1);
    }
    const midpoint=filmCopyLayers(boundary/6);
    near(midpoint[boundary-1].opacity,0);near(midpoint[boundary].opacity,0);
    near(midpoint[boundary-1].y,-14);near(midpoint[boundary].y,14);
    const incoming=forward.map(layers=>layers[boundary].opacity);
    assert.ok(incoming.every((value,i)=>i===0||value>=incoming[i-1]));
    near(forward[0][boundary-1].opacity,1);near(forward.at(-1)[boundary].opacity,1);
  }
});

test('reduced motion and failed media retain a single stationary chapter',()=>{
  for(const progress of [0,.15,1/6,.32,1/3,.5,.67,.83,1]){
    const layers=filmCopyLayers(progress,true);
    assert.deepEqual(layers.filter(layer=>layer.opacity>0).map(layer=>layer.index),[filmChapter(progress)]);
    assert.ok(layers.every(layer=>layer.y===0));
  }
});

test('film copy clamps invalid and endpoint progress without fading the first or last story',()=>{
  for(const progress of [-1,0,NaN,Infinity])assert.equal(filmCopyLayers(progress)[0].opacity,1);
  for(const progress of [1,2])assert.equal(filmCopyLayers(progress)[5].opacity,1);
});
